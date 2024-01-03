use openzeppelin::token::erc20::interface::IERC20Dispatcher;
use starknet::{ContractAddress, ClassHash};

//TODO: move out
fn sort_tokens(
    tokenA: ContractAddress, tokenB: ContractAddress
) -> (ContractAddress, ContractAddress) {
    let tokenA: felt252 = tokenA.into();
    let tokenB: felt252 = tokenB.into();
    let tokenA: u256 = tokenA.into();
    let tokenB: u256 = tokenB.into();
    if tokenA < tokenB {
        let token0: felt252 = tokenA.try_into().unwrap();
        let token1: felt252 = tokenB.try_into().unwrap();
        (token0.try_into().unwrap(), token1.try_into().unwrap())
    } else {
        let token0: felt252 = tokenB.try_into().unwrap();
        let token1: felt252 = tokenA.try_into().unwrap();
        (token0.try_into().unwrap(), token1.try_into().unwrap())
    }
}

#[starknet::interface]
trait ILaunchpad<T> {
    fn launch_token(ref self: T, params: EkuboLaunchParameters) -> u64;
}

#[starknet::contract]
mod Launchpad {
    use debug::PrintTrait;
    use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait, ILocker};
    use ekubo::interfaces::core::{PoolKey};
    use ekubo::interfaces::erc20::{IERC20DispatcherTrait};
    use ekubo::shared_locker::{call_core_with_callback, consume_callback_data};
    use ekubo::types::bounds::{Bounds};
    use ekubo::types::{i129::i129};
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::{ContractAddress, ClassHash, get_contract_address, get_caller_address};
    use super::{ILaunchpad, EkuboLaunchParameters, sort_tokens};
    use unruggable::exchanges::ekubo::interfaces::{
        ITokenRegistryDispatcher, IPositionsDispatcher, IPositionsDispatcherTrait,
        IOwnedNFTDispatcher, IOwnedNFTDispatcherTrait,
    };
    use unruggable::exchanges::ekubo::owned_nft::{OwnedNFT};

    #[storage]
    struct Storage {
        core: ICoreDispatcher,
        registry: ITokenRegistryDispatcher,
        positions: IPositionsDispatcher,
        nft: IOwnedNFTDispatcher,
        token_class_hash: ClassHash,
    }

    #[derive(starknet::Event, Drop)]
    struct Launched {
        params: EkuboLaunchParameters,
        caller: ContractAddress,
        token_id: u64,
    }

    #[derive(starknet::Event, Drop)]
    #[event]
    enum Event {
        Launched: Launched,
    }


    #[derive(Serde, Drop, Copy)]
    struct LaunchCallback {
        params: EkuboLaunchParameters,
    }

    #[derive(Serde, Drop, Copy)]
    struct WithdrawFeesCallback {
        recipient: ContractAddress,
    }

    #[derive(Serde, Drop, Copy)]
    enum CallbackData {
        WithdrawFeesCallback: WithdrawFeesCallback,
        LaunchCallback: LaunchCallback,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        core: ICoreDispatcher,
        registry: ITokenRegistryDispatcher,
        positions: IPositionsDispatcher,
        nft_class_hash: ClassHash,
        token_uri_base: felt252,
    ) {
        self.core.write(core);
        self.registry.write(registry);
        self.positions.write(positions);

        self
            .nft
            .write(
                OwnedNFT::deploy(
                    nft_class_hash: nft_class_hash,
                    controller: get_contract_address(),
                    name: 'Unruggable Launchpad NFT',
                    symbol: 'Unruggable EkuLaunch',
                    token_uri_base: token_uri_base,
                    salt: 0
                )
            );
    }

    #[external(v0)]
    impl LaunchpadImpl of ILaunchpad<ContractState> {
        fn launch_token(ref self: ContractState, params: EkuboLaunchParameters) -> u64 {
            let caller = get_caller_address();

            let token_id = self.nft.read().mint(caller);

            // Call the core with a callback to deposit and mint the LP tokens.
            call_core_with_callback::<
                CallbackData, ()
            >(self.core.read(), @CallbackData::LaunchCallback(LaunchCallback { params }));

            self.emit(Launched { params, caller, token_id });

            token_id
        }
    }

    #[external(v0)]
    impl LockerImpl of ILocker<ContractState> {
        fn locked(ref self: ContractState, id: u32, data: Array<felt252>) -> Array<felt252> {
            let core = self.core.read();

            match consume_callback_data::<CallbackData>(core, data) {
                CallbackData::WithdrawFeesCallback(_) => { // todo: withdraw the eth fees for the lp
                },
                CallbackData::LaunchCallback(params) => {
                    let launch_params: EkuboLaunchParameters = params.params;
                    let (token0, token1) = sort_tokens(
                        launch_params.token_address, launch_params.counterparty_address
                    );

                    // The price in a pool is expressed as token1 per token0.
                    // If you have an ETH-USDC pool, the internal price is expressed as USDC per ETH.
                    let is_token1_counterparty = launch_params.counterparty_address == token1;
                    let is_price_in_counterparty = launch_params.token_address == token1;

                    // The initial_tick must correspond to the wanted initial price.
                    // If the price is expressed in token1/token0, the initial_tick must be positive.
                    // If the price is expressed in token0/token1, the initial_tick must be negative.
                    let (initial_tick, lower_bound, upper_bound) = if is_token1_counterparty {
                        (
                            i129 { sign: true, mag: launch_params.starting_tick },
                            i129 { sign: true, mag: launch_params.lower_bound },
                            i129 { sign: false, mag: launch_params.upper_bound }
                        )
                    } else {
                        (
                            i129 { sign: false, mag: launch_params.starting_tick },
                            i129 { sign: false, mag: launch_params.lower_bound },
                            i129 { sign: true, mag: launch_params.upper_bound },
                        )
                    };

                    let pool_key = PoolKey {
                        token0: token0,
                        token1: token1,
                        fee: launch_params.fee,
                        tick_spacing: launch_params.tick_spacing,
                        extension: 0.try_into().unwrap(),
                    };

                    core.maybe_initialize_pool(:pool_key, :initial_tick);

                    let token0 = ERC20ABIDispatcher { contract_address: token0 };
                    let token1 = ERC20ABIDispatcher { contract_address: token1 };
                    let positions = self.positions.read();

                    token0
                        .transfer(
                            recipient: positions.contract_address,
                            amount: token0.balanceOf(get_contract_address())
                        );

                    token1
                        .transfer(
                            recipient: positions.contract_address,
                            amount: token1.balanceOf(get_contract_address())
                        );

                    // The pool bounds must be set according to the tick spacing.
                    // For a typical infinite Uni-V2 range, the lower bound is
                    // MIN_PRICE = math.log(2**-128, 1.000001)
                    // tick_number = abs(MIN_PRICE // TICK_SPACING)
                    // tick_value = TICK_SPACING * tick_number
                    positions
                        .mint_and_deposit(
                            pool_key,
                            bounds: Bounds { lower: lower_bound, upper: upper_bound, },
                            min_liquidity: 0,
                        );

                    // Clear remaining balances
                    self.clear(token0.contract_address);
                    self.clear(token1.contract_address);
                }
            }

            Default::default() // no specific return data
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Clears the balances of this contract by sending them to the caller.
        fn clear(ref self: ContractState, token: ContractAddress) {
            let caller = get_caller_address();
            // Clear the position contract and get the tokens back
            let positions = IPositionsDispatcher {
                contract_address: self.positions.read().contract_address
            };
            positions.clear(token);

            // Clear this contract and send the tokens back to the caller
            let token = ERC20ABIDispatcher { contract_address: token };
            token.transfer(recipient: caller, amount: token.balanceOf(get_contract_address()));
        }
    }
}


#[derive(Copy, Drop, Serde)]
struct EkuboLaunchParameters {
    token_address: ContractAddress,
    counterparty_address: ContractAddress,
    fee: u128,
    tick_spacing: u128,
    // the sign of the starting tick and the boudns is determined by the address of the deployed token contract
    starting_tick: u128,
    lower_bound: u128,
    upper_bound: u128,
}

#[starknet::component]
mod EkuboComponent {
    use ERC20Component::InternalTrait; // required to use internals of ERC20Component
    use OwnableComponent::Ownable; // required to use internals of OwnableComponent
    use array::ArrayTrait;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use debug::PrintTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::interface::IERC20CamelOnly;
    use openzeppelin::token::erc20::interface::{
        IERC20, IERC20Metadata, ERC20ABIDispatcher, ERC20ABIDispatcherTrait
    };
    use starknet::{get_block_timestamp, ContractAddress};
    use super::{EkuboLaunchParameters, ILaunchpadDispatcher, ILaunchpadDispatcherTrait,};
    use unruggable::errors;
    use unruggable::locker::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
    use unruggable::tokens::interface::{
        IUnruggableAdditional, IUnruggableMemecoinCamel, IUnruggableMemecoinSnake
    };

    #[storage]
    struct Storage {}


    #[embeddable_as(EkuboAdapterImpl)]
    impl EkuboAdapter<
        TContractState,
        +HasComponent<TContractState>,
        // The contract embedding this componenet
        // must also embed ERC20Component
        impl ERC20: ERC20Component::HasComponent<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>,
        +IUnruggableMemecoinCamel<TContractState>,
        +IUnruggableMemecoinSnake<TContractState>,
        +IUnruggableAdditional<TContractState>,
        +Drop<TContractState>
    > of unruggable::exchanges::IAmmAdapter<ComponentState<TContractState>> {
        fn create_and_add_liquidity(
            ref self: ComponentState<TContractState>,
            exchange_address: ContractAddress,
            token_address: ContractAddress,
            counterparty_address: ContractAddress,
            unlock_time: u64,
            mut additional_parameters: Span<felt252>,
        ) -> Span<felt252> {
            let ekubo_launch_params: EkuboLaunchParameters = Serde::deserialize(
                ref additional_parameters
            )
                .expect('Invalid ekubo add liq params');

            // This component is made to be embedded inside the memecoin contract. In order to access
            // its functions, we need to get a mutable reference to the memecoin contract.
            let mut memecoin = self.get_contract_mut();

            // As the memecoin contract embeds ERC20Component, we need to get a mutable reference to
            // its ERC20 component in order to access its internal functions (such as _approve).
            let mut memecoin_erc20 = get_dep_component_mut!(ref self, ERC20);
            let mut memecoin_ownable = get_dep_component_mut!(ref self, Ownable);

            let this_address = starknet::get_contract_address();
            let caller_address = starknet::get_caller_address();
            let counterparty_token = ERC20ABIDispatcher { contract_address: counterparty_address, };

            // Create liquidity pool
            let ekubo_launchpad = ILaunchpadDispatcher { contract_address: exchange_address };
            assert(ekubo_launchpad.contract_address.is_non_zero(), errors::EXCHANGE_NOT_SUPPORTED);

            // Transfer the tokens to the launchpad contract.
            let memecoin_balance = memecoin.balanceOf(this_address);
            let counterparty_token_balance = counterparty_token.balanceOf(this_address);

            // Using internal transfer here as memecoin_erc20 is the component of THIS same contract
            // so the caller_address is not this_address - unlike counterparty_token which is an external call.
            //TODO! handle the case where starting_tick is not in line with the supplied LP amounts
            // and a portion of tokens sent are refunded by Ekubo
            memecoin_erc20
                ._transfer(this_address, ekubo_launchpad.contract_address, memecoin_balance);
            counterparty_token
                .transfer(ekubo_launchpad.contract_address, counterparty_token_balance);

            let nft_id = ekubo_launchpad.launch_token(ekubo_launch_params);
            //TODO: handle the NFT representing the LP

            // We make sure that no liquidity was returned to the depositor.
            // Otherwise, the LP deposit parameters were wrong.
            assert(memecoin_erc20.balanceOf(this_address) == 0, 'add liq memecoin failed');
            assert(counterparty_token.balanceOf(this_address) == 0, 'add liq counterparty failed');

            //TODO: lock tokens
            // assert(
            //     memecoin.balanceOf(ekubo_launchpad.contract_address) == memecoin_balance,
            //     'add liquidity meme failed'
            // );
            // assert(
            //     counterparty_token
            //         .balanceOf(ekubo_launchpad.contract_address) == counterparty_token_balance,
            //     'add liq counterparty failed'
            // );

            // // Lock LP tokens
            // let lock_manager_address = memecoin.lock_manager_address();
            // let lock_manager = ILockManagerDispatcher { contract_address: lock_manager_address };
            // pair.approve(lock_manager_address, liquidity_received);
            // let locked_address = lock_manager
            //     .lock_tokens(
            //         token: pair_address,
            //         amount: liquidity_received,
            //         :unlock_time,
            //         withdrawer: memecoin_ownable.owner(),
            //     );
            // assert(pair.balanceOf(locked_address) == liquidity_received, 'lock failed');

            let mut return_data = Default::default();
            Serde::serialize(@nft_id, ref return_data);
            return_data.span()
        }
    }
}
