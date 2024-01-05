use starknet::ContractAddress;
use unruggable::exchanges::ekubo::ekubo_adapter::EkuboLaunchParameters;
use unruggable::utils::ContractAddressOrder;

fn sort_tokens(
    tokenA: ContractAddress, tokenB: ContractAddress
) -> (ContractAddress, ContractAddress) {
    if tokenA < tokenB {
        (tokenA, tokenB)
    } else {
        (tokenB, tokenA)
    }
}

#[starknet::interface]
trait IEkuboLauncher<T> {
    fn launch_token(ref self: T, params: EkuboLaunchParameters) -> u64;
    fn withdraw_fees(ref self: T, recipient: ContractAddress); //TODO(ekubo)
}

#[starknet::contract]
mod EkuboLauncher {
    use debug::PrintTrait;
    use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait, ILocker};
    use ekubo::interfaces::core::{PoolKey};
    use ekubo::interfaces::erc20::{IERC20DispatcherTrait};
    use ekubo::shared_locker::{call_core_with_callback, consume_callback_data};
    use ekubo::types::bounds::{Bounds};
    use ekubo::types::{i129::i129};
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::{ContractAddress, ClassHash, get_contract_address, get_caller_address};
    use super::{IEkuboLauncher, EkuboLaunchParameters, sort_tokens};
    use unruggable::exchanges::ekubo::interfaces::{
        ITokenRegistryDispatcher, IPositionsDispatcher, IPositionsDispatcherTrait,
        IOwnedNFTDispatcher, IOwnedNFTDispatcherTrait,
    };
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };
    use unruggable::utils::math::PercentageMath;

    #[storage]
    struct Storage {
        core: ICoreDispatcher,
        registry: ITokenRegistryDispatcher,
        positions: IPositionsDispatcher,
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
    ) {
        self.core.write(core);
        self.registry.write(registry);
        self.positions.write(positions);
    }

    #[external(v0)]
    impl EkuboLauncherImpl of IEkuboLauncher<ContractState> {
        fn launch_token(ref self: ContractState, params: EkuboLaunchParameters) -> u64 {
            let caller = get_caller_address();

            // Call the core with a callback to deposit and mint the LP tokens.
            let nft_id = call_core_with_callback::<
                CallbackData, u64
            >(self.core.read(), @CallbackData::LaunchCallback(LaunchCallback { params }));

            // Clear remaining balances. This is done _after_ the callback by core,
            // otherwise the caller in the context would be the core.
            self.clear(params.token_address);
            self.clear(params.counterparty_address);

            self.emit(Launched { params, caller, token_id: nft_id });

            nft_id
        }

        fn withdraw_fees(ref self: ContractState, recipient: ContractAddress) {
            //TODO
            call_core_with_callback::<
                CallbackData, u64
            >(
                self.core.read(),
                @CallbackData::WithdrawFeesCallback(WithdrawFeesCallback { recipient })
            );

            panic_with_felt252('unimplemented')
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

                    // The initial_tick must correspond to the wanted initial price in counterparty/MEME
                    // The ekubo prices are always in TOKEN1/TOKEN0.
                    // The initial_tick is the lower bound if the counterparty is token1, the upper bound otherwise.
                    let (initial_tick, lower_bound, upper_bound) = if is_token1_counterparty {
                        (
                            i129 {
                                sign: launch_params.starting_tick.sign,
                                mag: launch_params.starting_tick.mag
                            },
                            i129 {
                                sign: launch_params.starting_tick.sign,
                                mag: launch_params.starting_tick.mag
                            },
                            i129 { sign: false, mag: launch_params.bound },
                        )
                    } else {
                        // The initial tick sign is reversed if the counterparty is token0.
                        // as the price provided was expressed in token1/token0.
                        (
                            i129 {
                                sign: !launch_params.starting_tick.sign,
                                mag: launch_params.starting_tick.mag
                            },
                            i129 { sign: true, mag: launch_params.bound },
                            i129 {
                                sign: !launch_params.starting_tick.sign,
                                mag: launch_params.starting_tick.mag
                            },
                        )
                    };

                    core.maybe_initialize_pool(:pool_key, :initial_tick);

                    // Transfer the entire balance of the launched token to be used in the LP.
                    launched_token
                        .transfer(
                            recipient: positions.contract_address,
                            amount: launched_token.balanceOf(get_contract_address())
                        );

                    // The pool bounds must be set according to the tick spacing.
                    // The bounds were previously computed to provide yield covering the entire interval
                    // [lower_bound, starting_tick]  or [starting_tick, upper_bound] depending on the counterparty.
                    let (id, _) = positions
                        .mint_and_deposit(
                            pool_key,
                            bounds: Bounds { lower: lower_bound, upper: upper_bound, },
                            min_liquidity: 0
                        );
                }
            }

            array![id.into()]
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
