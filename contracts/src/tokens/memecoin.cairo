//! `UnruggableMemecoin` is an ERC20 token has additional features to prevent rug pulls.
use starknet::ContractAddress;


#[derive(Copy, Drop, starknet::Store, Serde)]
enum LiquidityType {
    ERC20: ContractAddress,
    NFT: u64
}

#[starknet::contract]
mod UnruggableMemecoin {
    use core::traits::TryInto;
    use core::zeroable::Zeroable;
    use debug::PrintTrait;
    use integer::BoundedInt;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::interface::IOwnable;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::erc20::ERC20Component::InternalTrait;

    use openzeppelin::token::erc20::interface::{
        IERC20, IERC20Metadata, ERC20ABIDispatcher, ERC20ABIDispatcherTrait
    };
    use starknet::{
        ContractAddress, contract_address_const, get_contract_address, get_caller_address,
        get_tx_info, get_block_timestamp
    };
    use super::LiquidityType;

    use unruggable::errors;
    use unruggable::exchanges::jediswap_adapter::{
        IJediswapFactoryDispatcher, IJediswapFactoryDispatcherTrait, IJediswapRouterDispatcher,
        IJediswapRouterDispatcherTrait
    };
    use unruggable::exchanges::{SupportedExchanges};
    use unruggable::factory::{IFactory, IFactoryDispatcher, IFactoryDispatcherTrait};
    use unruggable::locker::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinSnake, IUnruggableMemecoinCamel, IUnruggableAdditional
    };
    use unruggable::utils::math::PercentageMath;

    // Components.
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    // Constants.
    /// The maximum number of holders allowed before launch.
    /// This is to prevent the contract from being is_launched with a large number of holders.
    /// Once reached, transfers are disabled until the memecoin is is_launched.
    const MAX_HOLDERS_BEFORE_LAUNCH: u8 = 10;
    /// The maximum percentage of the total supply that can be allocated to the team.
    /// This is to prevent the team from having too much control over the supply.
    const MAX_SUPPLY_PERCENTAGE_TEAM_ALLOCATION: u16 = 1_000; // 10%
    /// The maximum percentage of the supply that can be bought at once.
    //TODO: discuss whether this should be a constant or a parameter
    const MAX_PERCENTAGE_BUY_LAUNCH: u8 = 200; // 2%

    #[storage]
    struct Storage {
        marker_v_0: (),
        pre_launch_holders_count: u8,
        team_allocation: u256,
        tx_hash_tracker: LegacyMap<ContractAddress, felt252>,
        transfer_restriction_delay: u64,
        launch_time: u64,
        factory_contract: ContractAddress,
        liquidity_type: Option<LiquidityType>,
        // Components.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    /// Constructor called once when the contract is deployed.
    /// # Arguments
    /// * `owner` - The owner of the contract.
    /// * `transfer_restriction_delay` - Delay timestamp to release transfer amount check.
    /// * `name` - The name of the token.
    /// * `symbol` - The symbol of the token.
    /// * `initial_supply` - The initial supply of the token.
    /// * `initial_holders` - The initial holders of the token, an array of holder_address
    /// * `initial_holders_amounts` - The initial amounts of tokens minted to the initial holders, an array of amounts
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        transfer_restriction_delay: u64,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        initial_holders: Span<ContractAddress>,
        initial_holders_amounts: Span<u256>,
    ) {
        self.erc20.initializer(name, symbol);

        self.ownable.initializer(owner);

        self.liquidity_type.write(Option::None);

        // Initialize the token / internal logic
        self
            .initializer(
                factory_address: get_caller_address(),
                :transfer_restriction_delay,
                :initial_supply,
                :initial_holders,
                :initial_holders_amounts
            );
    }

    #[abi(embed_v0)]
    impl UnruggableEntrypoints of IUnruggableAdditional<ContractState> {
        fn is_launched(self: @ContractState) -> bool {
            self.launch_time.read().is_non_zero()
        }

        /// Returns the team allocation in tokens.
        fn get_team_allocation(self: @ContractState) -> u256 {
            self.team_allocation.read()
        }

        fn memecoin_factory_address(self: @ContractState) -> ContractAddress {
            self.factory_contract.read()
        }

        fn liquidity_type(self: @ContractState) -> Option<LiquidityType> {
            self.liquidity_type.read()
        }

        fn set_launched(ref self: ContractState, liquidity_type: LiquidityType) {
            self.assert_only_factory();
            assert(!self.is_launched(), errors::ALREADY_LAUNCHED);
            self.liquidity_type.write(Option::Some(liquidity_type));
            self.launch_time.write(get_block_timestamp());
            self.ownable._transfer_ownership(0.try_into().unwrap());
        }
    }

    #[abi(embed_v0)]
    impl SnakeEntrypoints of IUnruggableMemecoinSnake<ContractState> {
        fn total_supply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.erc20.allowance(owner, spender)
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let caller = get_caller_address();
            self.erc20._spend_allowance(sender, caller, amount);
            self._transfer(sender, recipient, amount);
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            self.erc20.approve(spender, amount)
        }
    }

    #[abi(embed_v0)]
    impl CamelEntrypoints of IUnruggableMemecoinCamel<ContractState> {
        fn totalSupply(self: @ContractState) -> u256 {
            self.total_supply()
        }
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.balance_of(account)
        }
        fn transferFrom(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            self.transfer_from(sender, recipient, amount)
        }
    }

    //
    // Internal
    //
    #[generate_trait]
    impl UnruggableMemecoinInternalImpl of UnruggableMemecoinInternalTrait {
        fn assert_only_factory(self: @ContractState) {
            assert(get_caller_address() == self.factory_contract.read(), errors::NOT_FACTORY);
        }
        // Initializes the state of the memecoin contract.
        ///
        /// This function sets the locker and factory contract addresses, enables a transfer limit delay,
        /// checks and allocates the team supply of the memecoin, and mints the remaining supply to the factory.
        ///
        /// # Arguments
        ///
        /// * `factory_address` - The address of the factory contract.
        /// * `transfer_restriction_delay` - The delay in seconds before transfers are no longer limited.
        /// * `initial_supply` - The initial supply of the memecoin.
        /// * `initial_holders` - A span of addresses that will hold the memecoin initially.
        /// * `initial_holders_amounts` - A span of amounts corresponding to the initial holders.
        ///
        /// # Returns
        /// * `u256` - The total amount of memecoin allocated to the team.
        fn initializer(
            ref self: ContractState,
            factory_address: ContractAddress,
            transfer_restriction_delay: u64,
            initial_supply: u256,
            initial_holders: Span<ContractAddress>,
            initial_holders_amounts: Span<u256>
        ) {
            // Internal Registry
            self.factory_contract.write(factory_address);

            // Enable a transfer limit - until this time has passed,
            // transfers are limited to a certain amount.
            self.transfer_restriction_delay.write(transfer_restriction_delay);

            let team_allocation = self
                .check_and_allocate_team_supply(
                    :initial_supply, :initial_holders, :initial_holders_amounts
                );

            // Mint remaining supply to the contract
            self.erc20._mint(recipient: factory_address, amount: initial_supply - team_allocation);
        }

        /// Transfers tokens from the sender to the recipient, by applying relevant transfer restrictions.
        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            // When we call launch_memecoin(), we invoke the add_liquidity() of the router,
            // which performs a transferFrom() to send the tokens to the pool.
            // Therefore, we need to bypass this validation if the sender is the memecoin contract.
            if sender != get_contract_address() {
                self.apply_transfer_restrictions(sender, recipient, amount)
            }
            self.erc20._transfer(sender, recipient, amount);
        }

        /// Applies the relevant transfer restrictions, if the timing for restrictions has not elapsed yet.
        /// - The amount of tokens transferred does not exceed a certain percentage of the total supply.
        /// - Before launch, the number of holders and their allocation does not exceed the maximum allowed.
        /// - After launch, the transfer amount does not exceed a certain percentage of the total supply.
        /// and the recipient has not already received tokens in the current transaction.
        ///
        /// # Arguments
        ///
        /// * `sender` - The address of the sender.
        /// * `recipient` - The address of the recipient.
        /// * `amount` - The amount of tokens to transfer.
        fn apply_transfer_restrictions(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            if self.is_after_time_restrictions() {
                return;
            }

            if !self.is_launched() {
                self.enforce_prelaunch_holders_limit(sender, recipient, amount);
            } else {
                //TODO: make sure restrictions are compatible with ekubo and aggregators
                let liquidity_type = self.liquidity_type.read().unwrap();
                match liquidity_type {
                    LiquidityType::ERC20(pair) => {
                        if (get_caller_address() == pair || recipient == pair) {
                            return;
                        }
                    },
                    LiquidityType::NFT(_) => {}
                }

                assert(
                    amount <= self.total_supply().percent_mul(MAX_PERCENTAGE_BUY_LAUNCH.into()),
                    'Max buy cap reached'
                );

                self.ensure_not_multicall(recipient);
            }
        }

        /// Checks if the current time is after the launch period.
        ///
        /// # Returns
        ///
        /// * `bool` - True if the current time is after the launch period, false otherwise.
        ///
        fn is_after_time_restrictions(ref self: ContractState) -> bool {
            let current_time = get_block_timestamp();
            current_time >= (self.launch_time.read() + self.transfer_restriction_delay.read())
                && self.is_launched()
        }

        /// Checks and allocates the team supply of the memecoin.
        ///
        /// Checks that the number of initial holders and their corresponding amounts are equal,
        /// and that the number of initial holders does not exceed the maximum allowed.
        /// It then calculates the maximum team allocation as a percentage of the initial supply,
        /// and iteratively allocates the supply to each initial holder, ensuring that the total allocation does not exceed the maximu authorized.
        /// The function then updates the `team_allocation` and `pre_launch_holders_count` in the contract state.
        ///
        /// # Arguments
        ///
        /// * `initial_supply` - The initial supply of the memecoin.
        /// * `initial_holders` - A span of addresses that will hold the memecoin initially.
        /// * `initial_holders_amounts` - A span of amounts corresponding to the initial holders.
        ///
        /// # Returns
        ///
        /// * `u256` - The total amount of memecoin allocated to the team.
        ///
        fn check_and_allocate_team_supply(
            ref self: ContractState,
            initial_supply: u256,
            initial_holders: Span<ContractAddress>,
            initial_holders_amounts: Span<u256>
        ) -> u256 {
            assert(initial_holders.len() == initial_holders_amounts.len(), errors::ARRAYS_LEN_DIF);
            assert(
                initial_holders.len() <= MAX_HOLDERS_BEFORE_LAUNCH.into(),
                errors::MAX_HOLDERS_REACHED
            );

            let max_team_allocation = initial_supply
                .percent_mul(MAX_SUPPLY_PERCENTAGE_TEAM_ALLOCATION.into());
            let mut team_allocation: u256 = 0;
            let mut i: usize = 0;
            loop {
                if i == initial_holders.len() {
                    break;
                }

                let address = *initial_holders.at(i);
                let amount = *initial_holders_amounts.at(i);

                team_allocation += amount;
                assert(team_allocation <= max_team_allocation, errors::MAX_TEAM_ALLOCATION_REACHED);

                // Mint token to the holder
                self.erc20._mint(recipient: address, :amount);

                i += 1;
            };
            self.team_allocation.write(team_allocation);
            self.pre_launch_holders_count.write(initial_holders.len().try_into().unwrap());

            team_allocation
        }

        /// Ensures that the current call is not a part of a multicall.
        ///
        /// By keeping track of the last transaction hash each address has received tokens at,
        /// we can ensure that the current call is not part of a transaction already performed.
        ///
        /// # Arguments
        /// * `recipient` - The contract address of the recipient.
        //TODO(audit): Verify whether this can cause a problem for trading through aggregators, that can
        // do multiple transfers when using complex routes.
        #[inline(always)]
        fn ensure_not_multicall(ref self: ContractState, recipient: ContractAddress) {
            let tx_hash: felt252 = get_tx_info().unbox().transaction_hash;
            assert(self.tx_hash_tracker.read(recipient) != tx_hash, 'Multi calls not allowed');
            self.tx_hash_tracker.write(recipient, tx_hash);
        }


        /// Enforces that the number of holders does not exceed the maximum allowed.
        ///
        /// When transfers are done between addresses that already
        /// own tokens, we do not increment the number of holders.
        /// It only gets incremented when the recipient holds no tokens.
        /// If the sender will no longer hold tokens after the transfer, the
        /// number of holders is decremented.
        ///
        /// # Arguments
        ///
        /// * `sender` - The sender of the tokens being transferred.
        /// * `recipient` - The recipient of the tokens being transferred.
        /// * `amount` - The amount of tokens being transferred.
        ///
        #[inline(always)]
        fn enforce_prelaunch_holders_limit(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            // If this is not a mint and the sender will no longer hold tokens after the transfer,
            // decrement the holders count.
            //TODO: verify whether sender can _actually_ be zero - as this function is called from _transfer,
            // which is supposedly not called from the zero address.
            if sender.is_non_zero() && self.balanceOf(sender) == amount {
                let current_holders_count = self.pre_launch_holders_count.read();

                self.pre_launch_holders_count.write(current_holders_count - 1);
            }

            // If the recipient doesn't hold tokens yet - increment the holders count
            if self.balanceOf(recipient).is_zero() {
                let current_holders_count = self.pre_launch_holders_count.read();

                assert(
                    current_holders_count < MAX_HOLDERS_BEFORE_LAUNCH, errors::MAX_HOLDERS_REACHED
                );

                self.pre_launch_holders_count.write(current_holders_count + 1);
            }
        }
    }
}
