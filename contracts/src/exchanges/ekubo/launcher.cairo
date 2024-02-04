use ekubo::types::bounds::Bounds;
use ekubo::types::i129::{i129, i129Add};
use ekubo::types::keys::PoolKey;
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


#[starknet::interface]
trait IEkuboLauncher<T> {
    /// Launches a new token.
    ///
    /// This function calls the core contract with a callback to deposit and mint
    /// the LP tokens. The core of the launch logic is actually performed during the
    /// callback in the `locked` function, where the pool is initialized.
    ///
    /// The LP providing is done in two steps:
    /// 1. Provide liq between [starting_price, stating_tick+1], corresponding to the amount
    /// that the team can buy at the starting_price price. This ensures that the amount of liquidity in the pool
    /// never goes to zero, as all the tokens were initially in the pool.
    /// 2. Provide the rest of the liquidity in the pool, in the interval [starting_price+1, +inf].
    /// the tokens are transferred to the pool, and the Ekubo LP position is minted and
    /// transferred to this contract.  It then tracks the new ekubo position id with
    /// the position parameters in the `liquidity_positions` mapping in the
    /// contract, appends the owner's position to the `owner_to_positions` mapping,
    /// clears the remaining balances of the token and quote addresses, and emits a
    /// `Launched` event.
    ///
    /// # Arguments
    ///
    /// * `params` - The parameters for the token launch.
    ///
    /// # Returns
    ///
    /// * `(u64, EkuboLP)` - The ID and position of the new token.
    ///
    fn launch_token(ref self: T, params: EkuboLaunchParameters) -> (u64, EkuboLP);
    /// Transfers the ownership of a liquidity position held by this contract.
    ///
    /// This function transfers the ownership of a liquidity position from the caller to a recipient.
    /// It first reads the position to be transferred from the `liquidity_positions` mapping,
    /// asserts that the caller is the owner of the position,
    /// and asserts that the recipient address is not zero.
    /// It then reads the positions of the caller and recipient from the `owner_to_positions` mapping,
    /// removes the position from the caller's list,
    /// appends it to the recipient's list,
    /// and writes the updated position with the new owner to the `liquidity_positions` mapping.
    /// The underlying Ekubo LP position is not modified.
    ///
    /// # Arguments
    ///
    /// * `id` - The ID of the liquidity position to be transferred.
    /// * `recipient` - The address of the recipient.
    ///
    /// # Panics
    ///
    /// * If the caller is not the owner of the position.
    /// * If the recipient address is zero.
    ///
    fn transfer_position_ownership(ref self: T, id: u64, recipient: ContractAddress);
    /// Withdraws the fees collected from a liquidity position in quote tokens.
    ///
    /// This function reads the liquidity position from the `liquidity_positions` mapping,
    /// asserts that the caller is the owner of the position,
    /// and calls the core contract with a callback to withdraw the fees. The callback call withdraws the fees in both
    /// tokens from the Ekubo position, and transfers them to this contract.
    /// Upon return from the callback, it then checks if the quote address of the position is the same as the first token address returned by the callback.
    /// If it is, it reads the balance of the first token, transfers it to the recipient, and returns the balance.
    /// If it is not, it reads the balance of the second token, transfers it to the recipient, and returns the balance.
    /// The fees accumulated in the base token are not withdrawn.
    ///
    /// # Arguments
    ///
    /// * `id` - The ID of the liquidity position.
    /// * `recipient` - The address of the recipient.
    ///
    /// # Returns
    ///
    /// * `u256` - The amount of fees collected.
    ///
    /// # Panics
    ///
    /// * If the caller is not the owner of the position.
    ///
    fn withdraw_fees(ref self: T, id: u64, recipient: ContractAddress) -> u256;
    /// Returns the IDs of the tokens launched by a specific owner.
    ///
    /// This function reads the positions of the owner from the `owner_to_positions` mapping,
    /// and returns a span of the IDs of the tokens launched by the owner.
    ///
    /// # Arguments
    ///
    /// * `owner` - The address of the owner.
    ///
    /// # Returns
    ///
    /// * `Span<u64>` - A span of the IDs of the tokens launched by the owner.
    ///
    fn launched_tokens(self: @T, owner: ContractAddress) -> Span<u64>;
    /// Returns the details of a liquidity position.
    ///
    /// This function reads the liquidity position with the given ID from the `liquidity_positions` mapping,
    /// and returns a `EkuboLP` struct containing the details of the position.
    ///
    /// # Arguments
    ///
    /// * `id` - The ID of the liquidity position.
    ///
    /// # Returns
    ///
    /// * `EkuboLP` - A struct containing the details of the liquidity position.
    ///
    fn liquidity_position_details(self: @T, id: u64) -> EkuboLP;

    /// Returns the address of the ekubo core contract.
    fn ekubo_core_address(self: @T) -> ContractAddress;

    /// Returns the address of the ekubo router contract.
    fn ekubo_router_address(self: @T) -> ContractAddress;
}

#[starknet::contract]
mod EkuboLauncher {
    use alexandria_storage::list::{List, ListTrait};
    use debug::PrintTrait;
    use ekubo::components::clear::{IClearDispatcher, IClearDispatcherTrait};
    use ekubo::components::shared_locker::{call_core_with_callback, consume_callback_data};
    use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait, ILocker};
    use ekubo::interfaces::core::{PoolKey};
    use ekubo::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use ekubo::interfaces::positions::{IPositionsDispatcher, IPositionsDispatcherTrait};
    use ekubo::interfaces::router::{IRouterDispatcher, IRouterDispatcherTrait};
    use ekubo::types::bounds::{Bounds};
    use ekubo::types::{i129::i129};
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::SyscallResultTrait;
    use starknet::{ContractAddress, ClassHash, get_contract_address, get_caller_address, Store};
    use super::{IEkuboLauncher, EkuboLaunchParameters};
    use super::{StorableBounds, StorablePoolKey, StorableEkuboLP, EkuboLP};
    use unruggable::errors;
    use unruggable::exchanges::ekubo::errors::{NOT_POSITION_OWNER};
    use unruggable::exchanges::ekubo::helpers::{
        get_next_tick_bounds, get_initial_tick_from_starting_price
    };
    use unruggable::exchanges::ekubo::interfaces::{
        ITokenRegistryDispatcher, IOwnedNFTDispatcher, IOwnedNFTDispatcherTrait,
    };
    use unruggable::token::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };
    use unruggable::utils::math::PercentageMath;
    use unruggable::utils::sort_tokens;


    #[storage]
    struct Storage {
        core: ICoreDispatcher,
        registry: ITokenRegistryDispatcher,
        positions: IPositionsDispatcher,
        router: IRouterDispatcher,
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
        router: IRouterDispatcher,
    ) {
        self.core.write(core);
        self.registry.write(registry);
        self.positions.write(positions);
        self.router.write(router);
    }

    #[external(v0)]
    impl EkuboLauncherImpl of IEkuboLauncher<ContractState> {
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
            // is transferred.
            let mut owner_positions = self.owner_to_positions.read(params.owner);
            owner_positions.append(id);

            // Clear remaining balances. This is done _after_ the callback by core,
            // otherwise the caller in the context would be the core.
            let caller = get_caller_address();
            let ekubo_clear = IClearDispatcher {
                contract_address: self.positions.read().contract_address
            };
            ekubo_clear
                .clear_minimum_to_recipient(
                    IERC20Dispatcher { contract_address: params.token_address }, 0, caller
                );
            ekubo_clear
                .clear_minimum_to_recipient(
                    IERC20Dispatcher { contract_address: params.quote_address }, 0, caller
                );

            self.emit(Launched { params, owner: params.owner, token_id: id });

            (id, position)
        }


        fn transfer_position_ownership(
            ref self: ContractState, id: u64, recipient: ContractAddress
        ) {
            let position_to_transfer = self.liquidity_positions.read(id);
            self.assert_only_position_owner(position_to_transfer);

            assert(recipient.into() != 0_felt252, errors::RECIPIENT_ADDRESS_ZERO);

            let mut positions_of_owner = self.owner_to_positions.read(get_caller_address());

            // Remove position of the owner
            self.remove_position_from_list(id, positions_of_owner);

            let mut positions_of_recipient = self.owner_to_positions.read(recipient);

            // Add position to recipient
            positions_of_recipient.append(id);

            // Modify StorableEkuboLP owner value in storage for the corresponding ID
            let new_storable_ekubo_LP = StorableEkuboLP {
                owner: recipient,
                quote_address: position_to_transfer.quote_address,
                pool_key: position_to_transfer.pool_key,
                bounds: position_to_transfer.bounds,
            };

            self.liquidity_positions.write(id, new_storable_ekubo_LP);
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

        fn launched_tokens(self: @ContractState, owner: ContractAddress) -> Span<u64> {
            self.owner_to_positions.read(owner).array().unwrap_syscall().span()
        }

        fn liquidity_position_details(self: @ContractState, id: u64) -> EkuboLP {
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

        fn ekubo_core_address(self: @ContractState) -> ContractAddress {
            self.core.read().contract_address
        }

        fn ekubo_router_address(self: @ContractState) -> ContractAddress {
            self.router.read().contract_address
        }
    }

    #[external(v0)]
    impl LockerImpl of ILocker<ContractState> {
        /// Callback function called by the core contract.
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
                    positions.collect_fees(id, pool_key, bounds);

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
                    let pool_key = PoolKey {
                        token0: token0,
                        token1: token1,
                        fee: launch_params.pool_params.fee,
                        tick_spacing: launch_params.pool_params.tick_spacing,
                        extension: 0.try_into().unwrap(),
                    };

                    // The initial_tick must correspond to the wanted initial price in quote/MEME
                    // The ekubo prices are always in TOKEN1/TOKEN0.
                    // The initial_tick is the lower bound if the quote is token1, the upper bound otherwise.
                    let is_token1_quote = launch_params.quote_address == token1;
                    let (initial_tick, full_range_bounds) = get_initial_tick_from_starting_price(
                        launch_params.pool_params.starting_price,
                        launch_params.pool_params.bound,
                        is_token1_quote
                    );

                    // Initialize the pool at the initial tick.
                    //TODO: check if this can be frontran
                    //TODO: how to fix frontrunning possibilities by disabling create -> launch?
                    core.maybe_initialize_pool(:pool_key, :initial_tick);

                    // 1. Provide liq that must be put in the pool by the creator, equal
                    // to the percentage of the total supply allocated to the team,
                    // only at the starting_price price.
                    let launched_token = IUnruggableMemecoinDispatcher {
                        contract_address: launch_params.token_address
                    };
                    let this = get_contract_address();
                    let liquidity_for_team = launched_token.balanceOf(this)
                        - launch_params.lp_supply;
                    let single_tick_bound = get_next_tick_bounds(
                        launch_params.pool_params.starting_price,
                        launch_params.pool_params.tick_spacing,
                        is_token1_quote
                    );
                    self
                        .supply_liquidity(
                            pool_key,
                            launch_params.token_address,
                            liquidity_for_team,
                            single_tick_bound
                        );

                    let ekubo_router = self.router.read();
                    // let market_depth = ekubo_router
                    //     .get_market_depth(pool_key, 985392111309755760868507187842908160);

                    // 2. Provide the liquidity to actually initialize the public pool with
                    // The pool bounds must be set according to the tick spacing.
                    // The bounds were previously computed to provide yield covering the entire interval
                    // [lower_bound, starting_price]  or [starting_price, upper_bound] depending on the quote.
                    let id = self
                        .supply_liquidity(
                            pool_key,
                            launch_params.token_address,
                            launch_params.lp_supply,
                            full_range_bounds
                        );

                    // At this point, the pool is composed by:
                    // n% of liquidity at precise starting tick, reserved for the team to buy
                    // the rest of the liquidity, in bounds [starting_price, +inf];

                    let mut return_data: Array<felt252> = Default::default();
                    Serde::serialize(@id, ref return_data);
                    Serde::serialize(
                        @EkuboLP {
                            owner: launch_params.owner,
                            quote_address: launch_params.quote_address,
                            pool_key,
                            bounds: full_range_bounds
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
        /// Ensures that the caller is the owner of the specified position.
        ///
        /// # Arguments
        ///
        /// * `position_to_transfer` - The LP position to transfer.
        ///
        /// # Panics
        ///
        /// This function will panic if:
        ///
        /// * The caller's address is not the same as the `owner` of the `position_to_transfer` (error code: `NOT_POSITION_OWNER`).
        ///
        fn assert_only_position_owner(self: @ContractState, position_to_transfer: StorableEkuboLP) {
            let owner_of_position: ContractAddress = position_to_transfer.owner;
            assert(get_caller_address() == owner_of_position, NOT_POSITION_OWNER);
        }

        /// Removes the id of a position from the list of positions of a user.
        ///
        /// Internally, this function reads the list of positions of the specified `owner` from the 'owner_to_positions' mapping.
        /// It then iterates over the list and replaces the specified `position` with the last element of the list.
        /// The length of the list is then decremented by one, and the last element of the list is set to zero.
        fn remove_position_from_list(self: @ContractState, position: u64, mut list: List<u64>) {
            let list_len = list.len();
            let mut i = 0;
            loop {
                if i == list_len {
                    break;
                }
                let current_position = list[i];
                if current_position != position {
                    i += 1;
                    continue;
                }
                let last_element = list[list_len - 1];
                list.set(i, last_element);
                list.set(list_len - 1, 0.try_into().unwrap());
                list.len -= 1;
                Store::write(list.address_domain, list.base, list.len).unwrap_syscall();
                break;
            }
        }

        fn supply_liquidity(
            ref self: ContractState,
            pool_key: PoolKey,
            token: ContractAddress,
            amount: u256,
            bounds: Bounds
        ) -> u64 {
            let positions = self.positions.read();
            // The token must be transferred to the positions contract before calling mint.
            ERC20ABIDispatcher { contract_address: token }
                .transfer(recipient: positions.contract_address, :amount);

            let (id, liquidity) = positions.mint_and_deposit(pool_key, bounds, min_liquidity: 0);
            id
        }
    }
}
