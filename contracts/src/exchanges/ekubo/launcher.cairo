use ekubo::types::bounds::Bounds;
use ekubo::types::i129::i129;
use ekubo::types::keys::PoolKey;
use starknet::ContractAddress;
use unruggable::exchanges::ekubo::ekubo_adapter::{EkuboLaunchParameters};
use unruggable::utils::ContractAddressOrder;

//! Temporary workaround to store bounds and pool keys
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
struct StorableEkuboLP {
    owner: ContractAddress,
    quote_address: ContractAddress,
    pool_key: StorablePoolKey,
    bounds: StorableBounds,
}

#[derive(Copy, Drop, Serde)]
struct EkuboLP {
    owner: ContractAddress,
    quote_address: ContractAddress,
    pool_key: PoolKey,
    bounds: Bounds,
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
    fn launched_tokens(ref self: T, owner: ContractAddress) -> Span<u64>;
    fn liquidity_position_details(ref self: T, id: u64) -> EkuboLP;
}

#[starknet::contract]
mod EkuboLauncher {
    use alexandria_storage::list::{List, ListTrait};
    use debug::PrintTrait;
    use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait, ILocker};
    use ekubo::interfaces::core::{PoolKey};
    use ekubo::interfaces::erc20::{IERC20DispatcherTrait};
    use ekubo::shared_locker::{call_core_with_callback, consume_callback_data};
    use ekubo::types::bounds::{Bounds};
    use ekubo::types::{i129::i129};
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::SyscallResultTrait;
    use starknet::{ContractAddress, ClassHash, get_contract_address, get_caller_address};
    use super::{IEkuboLauncher, EkuboLaunchParameters, sort_tokens};
    use super::{StorableBounds, StorablePoolKey, StorableEkuboLP, EkuboLP};
    use unruggable::errors;
    use unruggable::exchanges::ekubo::interfaces::{
        ITokenRegistryDispatcher, IPositionsDispatcher, IPositionsDispatcherTrait,
        IOwnedNFTDispatcher, IOwnedNFTDispatcherTrait,
    };
    use unruggable::token::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };
    use unruggable::utils::math::PercentageMath;


    #[storage]
    struct Storage {
        core: ICoreDispatcher,
        registry: ITokenRegistryDispatcher,
        positions: IPositionsDispatcher,
        factory: ContractAddress,
        liquidity_positions: LegacyMap<u64, StorableEkuboLP>,
        owner_to_positions: LegacyMap<ContractAddress, List<u64>>
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
        liquidity_type: EkuboLP,
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
        //TODO(ekubo): add support to transfer the ownership of the LP to collect fees.
        fn launch_token(ref self: ContractState, params: EkuboLaunchParameters) -> (u64, EkuboLP) {
            // Call the core with a callback to deposit and mint the LP tokens.
            let (id, position) = call_core_with_callback::<
                CallbackData, (u64, EkuboLP)
            >(self.core.read(), @CallbackData::LaunchCallback(LaunchCallback { params }));

            self
                .liquidity_positions
                .write(
                    id,
                    StorableEkuboLP {
                        owner: position.owner,
                        quote_address: position.quote_address,
                        pool_key: StorablePoolKey {
                            token0: position.pool_key.token0,
                            token1: position.pool_key.token1,
                            fee: position.pool_key.fee,
                            tick_spacing: position.pool_key.tick_spacing,
                            extension: position.pool_key.extension,
                        },
                        bounds: StorableBounds {
                            lower: position.bounds.lower, upper: position.bounds.upper
                        }
                    }
                );

            // Append the owner's position to storage. It can only be removed if the ownership
            // is transfered.
            let mut owner_positions = self.owner_to_positions.read(params.owner);
            owner_positions.append(id);

            // Clear remaining balances. This is done _after_ the callback by core,
            // otherwise the caller in the context would be the core.
            self.clear(params.token_address);
            self.clear(params.quote_address);

            self.emit(Launched { params, owner: params.owner, token_id: id });

            (id, position)
        }

        fn withdraw_fees(ref self: ContractState, id: u64, recipient: ContractAddress) -> u256 {
            let stored_position = self.liquidity_positions.read(id);
            let liquidity_type = EkuboLP {
                owner: stored_position.owner,
                quote_address: stored_position.quote_address,
                pool_key: PoolKey {
                    token0: stored_position.pool_key.token0,
                    token1: stored_position.pool_key.token1,
                    fee: stored_position.pool_key.fee,
                    tick_spacing: stored_position.pool_key.tick_spacing,
                    extension: stored_position.pool_key.extension,
                },
                bounds: Bounds {
                    lower: stored_position.bounds.lower, upper: stored_position.bounds.upper,
                }
            };
            //TODO: perhaps factory should handle this
            assert(liquidity_type.owner == get_caller_address(), errors::CALLER_NOT_OWNER);
            let (token0, token1) = call_core_with_callback::<
                CallbackData, (ContractAddress, ContractAddress)
            >(
                self.core.read(),
                @CallbackData::WithdrawFeesCallback(
                    WithdrawFeesCallback { id, liquidity_type, recipient }
                )
            );

            let fee_collected = if liquidity_type.quote_address == token0 {
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

        fn launched_tokens(ref self: ContractState, owner: ContractAddress) -> Span<u64> {
            self.owner_to_positions.read(owner).array().unwrap_syscall().span()
        }

        fn liquidity_position_details(ref self: ContractState, id: u64) -> EkuboLP {
            let storable_pos = self.liquidity_positions.read(id);
            EkuboLP {
                owner: storable_pos.owner,
                quote_address: storable_pos.quote_address,
                pool_key: PoolKey {
                    token0: storable_pos.pool_key.token0,
                    token1: storable_pos.pool_key.token1,
                    fee: storable_pos.pool_key.fee,
                    tick_spacing: storable_pos.pool_key.tick_spacing,
                    extension: storable_pos.pool_key.extension,
                },
                bounds: Bounds {
                    lower: storable_pos.bounds.lower, upper: storable_pos.bounds.upper,
                }
            }
        }
    }

    #[external(v0)]
    impl LockerImpl of ILocker<ContractState> {
        fn locked(ref self: ContractState, id: u32, data: Array<felt252>) -> Array<felt252> {
            let core = self.core.read();

            match consume_callback_data::<CallbackData>(core, data) {
                CallbackData::WithdrawFeesCallback(params) => {
                    let WithdrawFeesCallback{id, liquidity_type, recipient } = params;
                    let positions = self.positions.read();
                    let EkuboLP{owner, quote_address: _, pool_key, bounds } = liquidity_type;
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
                        launch_params.token_address, launch_params.quote_address
                    );
                    let launched_token = IUnruggableMemecoinDispatcher {
                        contract_address: launch_params.token_address
                    };
                    let positions = self.positions.read();
                    let this = get_contract_address();
                    let pool_key = PoolKey {
                        token0: token0,
                        token1: token1,
                        fee: launch_params.pool_params.fee,
                        tick_spacing: launch_params.pool_params.tick_spacing,
                        extension: 0.try_into().unwrap(),
                    };

                    let is_token1_quote = launch_params.quote_address == token1;

                    // The initial_tick must correspond to the wanted initial price in quote/MEME
                    // The ekubo prices are always in TOKEN1/TOKEN0.
                    // The initial_tick is the lower bound if the quote is token1, the upper bound otherwise.
                    let (initial_tick, bounds) = if is_token1_quote {
                        (
                            i129 {
                                sign: launch_params.pool_params.starting_tick.sign,
                                mag: launch_params.pool_params.starting_tick.mag
                            },
                            Bounds {
                                lower: i129 {
                                    sign: launch_params.pool_params.starting_tick.sign,
                                    mag: launch_params.pool_params.starting_tick.mag
                                },
                                upper: i129 { sign: false, mag: launch_params.pool_params.bound }
                            }
                        )
                    } else {
                        // The initial tick sign is reversed if the quote is token0.
                        // as the price provided was expressed in token1/token0.
                        (
                            i129 {
                                sign: !launch_params.pool_params.starting_tick.sign,
                                mag: launch_params.pool_params.starting_tick.mag
                            },
                            Bounds {
                                lower: i129 { sign: true, mag: launch_params.pool_params.bound },
                                upper: i129 {
                                    sign: !launch_params.pool_params.starting_tick.sign,
                                    mag: launch_params.pool_params.starting_tick.mag
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
                    // [lower_bound, starting_tick]  or [starting_tick, upper_bound] depending on the quote.
                    let (id, _) = positions.mint_and_deposit(pool_key, bounds, min_liquidity: 0);

                    let mut return_data: Array<felt252> = Default::default();
                    Serde::serialize(@id, ref return_data);
                    Serde::serialize(
                        @EkuboLP {
                            owner: launch_params.owner,
                            quote_address: launch_params.quote_address,
                            pool_key,
                            bounds
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
