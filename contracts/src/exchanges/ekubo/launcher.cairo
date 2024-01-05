use ekubo::types::i129::i129;
use starknet::ContractAddress;
use unruggable::exchanges::ekubo::ekubo_adapter::{EkuboLaunchParameters};
use unruggable::utils::ContractAddressOrder;

//! Temporary workaround to store bounds
#[derive(Copy, Drop, Serde, PartialEq, Hash, starknet::Store)]
struct StorableBounds {
    lower: i129,
    upper: i129,
}

//! Temporary workaround to store pool keys
#[derive(Copy, Drop, Serde, PartialEq, Hash, starknet::Store)]
struct StorablePoolKey {
    token0: ContractAddress,
    token1: ContractAddress,
    fee: u128,
    tick_spacing: u128,
    extension: ContractAddress,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
struct EkuboLP {
    owner: ContractAddress,
    counterparty_address: ContractAddress,
    pool_key: StorablePoolKey,
    bounds: StorableBounds,
}

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
    fn launch_token(ref self: T, params: EkuboLaunchParameters) -> (u64, EkuboLP);
    fn withdraw_fees(ref self: T, id: u64, recipient: ContractAddress) -> u256;
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
    use super::{StorableBounds, StorablePoolKey, EkuboLP};
    use unruggable::errors;
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
        factory: ContractAddress,
        liquidity_positions: LegacyMap<u64, EkuboLP>,
    // owner_to_positions: LegacyMap<ContractAddress, Array<u64>>, //TODO(fix)
    }

    #[derive(starknet::Event, Drop)]
    struct Launched {
        params: EkuboLaunchParameters,
        owner: ContractAddress,
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
        id: u64,
        liquidity_position: EkuboLP,
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
        fn launch_token(ref self: ContractState, params: EkuboLaunchParameters) -> (u64, EkuboLP) {
            // Call the core with a callback to deposit and mint the LP tokens.
            let (id, position) = call_core_with_callback::<
                CallbackData, (u64, EkuboLP)
            >(self.core.read(), @CallbackData::LaunchCallback(LaunchCallback { params }));

            self.liquidity_positions.write(id, position);

            // Clear remaining balances. This is done _after_ the callback by core,
            // otherwise the caller in the context would be the core.
            self.clear(params.token_address);
            self.clear(params.counterparty_address);

            self.emit(Launched { params, owner: params.owner, token_id: id });

            (id, position)
        }

        fn withdraw_fees(ref self: ContractState, id: u64, recipient: ContractAddress) -> u256 {
            let liquidity_position = self.liquidity_positions.read(id);
            //TODO: perhaps factory should handle this
            assert(liquidity_position.owner == get_caller_address(), errors::CALLER_NOT_OWNER);
            let (token0, token1) = call_core_with_callback::<
                CallbackData, (ContractAddress, ContractAddress)
            >(
                self.core.read(),
                @CallbackData::WithdrawFeesCallback(
                    WithdrawFeesCallback { id, liquidity_position, recipient }
                )
            );

            let fee_collected = if liquidity_position.counterparty_address == token0 {
                let token0 = ERC20ABIDispatcher { contract_address: token0 };
                let balance_token0 = token0.balanceOf(get_contract_address());
                token0.transfer(recipient, balance_token0);
                balance_token0
            } else {
                let token1 = ERC20ABIDispatcher { contract_address: token1 };
                let balance_token1 = token1.balanceOf(get_contract_address());
                token1.transfer(recipient, balance_token1);
                balance_token1
            };

            fee_collected
        }
    }

    #[external(v0)]
    impl LockerImpl of ILocker<ContractState> {
        fn locked(ref self: ContractState, id: u32, data: Array<felt252>) -> Array<felt252> {
            let core = self.core.read();

            match consume_callback_data::<CallbackData>(core, data) {
                CallbackData::WithdrawFeesCallback(params) => {
                    let WithdrawFeesCallback{id, liquidity_position, recipient } = params;
                    let positions = self.positions.read();
                    let EkuboLP{owner, counterparty_address: _, pool_key, bounds } =
                        liquidity_position;
                    let pool_key = PoolKey {
                        token0: pool_key.token0,
                        token1: pool_key.token1,
                        fee: pool_key.fee,
                        tick_spacing: pool_key.tick_spacing,
                        extension: pool_key.extension,
                    };
                    let bounds = Bounds { lower: bounds.lower, upper: bounds.upper, };
                    positions.withdraw(id, pool_key, bounds, 0, 0, 0, true);

                    // Transfer to recipient
                    let mut return_data = Default::default();
                    Serde::serialize(@pool_key.token0, ref return_data);
                    Serde::serialize(@pool_key.token1, ref return_data);
                    return_data
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
                    let (initial_tick, bounds) = if is_token1_counterparty {
                        (
                            i129 {
                                sign: launch_params.starting_tick.sign,
                                mag: launch_params.starting_tick.mag
                            },
                            Bounds {
                                lower: i129 {
                                    sign: launch_params.starting_tick.sign,
                                    mag: launch_params.starting_tick.mag
                                },
                                upper: i129 { sign: false, mag: launch_params.bound }
                            }
                        )
                    } else {
                        // The initial tick sign is reversed if the counterparty is token0.
                        // as the price provided was expressed in token1/token0.
                        (
                            i129 {
                                sign: !launch_params.starting_tick.sign,
                                mag: launch_params.starting_tick.mag
                            },
                            Bounds {
                                lower: i129 { sign: true, mag: launch_params.bound },
                                upper: i129 {
                                    sign: !launch_params.starting_tick.sign,
                                    mag: launch_params.starting_tick.mag
                                }
                            }
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
                    let (id, _) = positions.mint_and_deposit(pool_key, bounds, min_liquidity: 0);

                    let mut return_data: Array<felt252> = Default::default();
                    Serde::serialize(@id, ref return_data);
                    Serde::serialize(
                        @EkuboLP {
                            owner: launch_params.owner,
                            counterparty_address: launch_params.counterparty_address,
                            pool_key: StorablePoolKey {
                                token0: token0,
                                token1: token1,
                                fee: launch_params.fee,
                                tick_spacing: launch_params.tick_spacing,
                                extension: 0.try_into().unwrap(),
                            },
                            bounds: StorableBounds { lower: bounds.lower, upper: bounds.upper, },
                        },
                        ref return_data
                    );
                    return_data
                }
            }
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
