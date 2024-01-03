use starknet::ContractAddress;
use unruggable::exchanges::ekubo::ekubo_adapter::EkuboLaunchParameters;

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
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };
    use unruggable::exchanges::ekubo::owned_nft::{OwnedNFT};
    use unruggable::utils::math::PercentageMath;

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

            // Clear remaining balances. This is done _after_ the callback by core,
            // otherwise the caller in the context is not right
            self.clear(params.token_address);
            self.clear(params.counterparty_address);

            self.emit(Launched { params, caller, token_id });

            token_id
        }
    }

    #[external(v0)]
    impl LockerImpl of ILocker<ContractState> {
        fn locked(ref self: ContractState, id: u32, data: Array<felt252>) -> Array<felt252> {
            let core = self.core.read();

            match consume_callback_data::<CallbackData>(core, data) {
                CallbackData::WithdrawFeesCallback(_) => { //TODO(ekubo): enable withdraw of the LP
                },
                CallbackData::LaunchCallback(params) => {
                    let launch_params: EkuboLaunchParameters = params.params;
                    let (token0, token1) = sort_tokens(
                        launch_params.token_address, launch_params.counterparty_address
                    );
                    let launched_token = IUnruggableMemecoinDispatcher {
                        contract_address: launch_params.token_address
                    };
                    let positions = self.positions.read();
                    let this = get_contract_address();
                    let pool_key = PoolKey {
                        token0: token0,
                        token1: token1,
                        fee: launch_params.fee,
                        tick_spacing: launch_params.tick_spacing,
                        extension: 0.try_into().unwrap(),
                    };

                    let is_token1_counterparty = launch_params.counterparty_address == token1;

                    // The initial_tick must correspond to the wanted initial price.
                    // If the price is expressed in token1/token0, the initial_tick must be positive.
                    // If the price is expressed in token0/token1, the initial_tick must be negative.
                    // The initial_tick is the lower bound if the counterparty is token1,
                    // TODO: this only supports positive meme/counterparty ratios (negative eth/meme)
                    // If the meme has higher value than counterparty it should be the opposite
                    let (initial_tick, lower_bound, upper_bound) = if is_token1_counterparty {
                        (
                            i129 { sign: true, mag: launch_params.starting_tick },
                            i129 { sign: true, mag: launch_params.starting_tick },
                            i129 { sign: false, mag: launch_params.bound },
                        )
                    } else {
                        (
                            i129 { sign: false, mag: launch_params.starting_tick },
                            i129 { sign: true, mag: launch_params.bound },
                            i129 { sign: false, mag: launch_params.starting_tick },
                        )
                    };

                    core.maybe_initialize_pool(:pool_key, :initial_tick);

                    // Transfer the entire balance of the launched token to be used in the LP.
                    launched_token
                        .transfer(
                            recipient: positions.contract_address,
                            amount: launched_token.balanceOf(get_contract_address())
                        );

                    let team_alloc = launched_token.get_team_allocation();
                    let total_supply = launched_token.total_supply();

                    // The pool bounds must be set according to the tick spacing.
                    // As we always supply 1-sided liquidity,
                    // the lower bound is always the initial tick. The upper bound is the
                    // maximum tick for the given tick spacing as we want the LP provider to
                    // provide yield covering the entire upside.
                    // Min liquidity enforced is the total supply minus the team allocation.
                    let (id, liq) = positions
                        .mint_and_deposit(
                            pool_key,
                            bounds: Bounds { lower: lower_bound, upper: upper_bound, },
                            min_liquidity: 0
                        );
                    liq.print();
                    (total_supply - team_alloc).print();
                    PercentageMath::percent_mul(total_supply - team_alloc, 9900).print();
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
            let this = get_contract_address();
            let token = ERC20ABIDispatcher { contract_address: token };
            let positions = IPositionsDispatcher {
                contract_address: self.positions.read().contract_address
            };

            // Clear the position contract and get the tokens back
            positions.clear(token.contract_address);

            let balance = token.balanceOf(this);
            if balance == 0 {
                return;
            }

            // Clear this contract and send the tokens back to the caller
            token.transfer(recipient: caller, amount: token.balanceOf(this));
        }
    }
}
