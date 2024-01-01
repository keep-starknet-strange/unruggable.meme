//! `UnruggableMemecoin` is an ERC20 token has additional features to prevent rug pulls.
use starknet::ContractAddress;

#[starknet::contract]
mod UnruggableMemecoin {
    use debug::PrintTrait;
    use integer::BoundedInt;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::interface::IOwnable;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
    use openzeppelin::token::erc20::ERC20Component;

    use openzeppelin::token::erc20::interface::{
        IERC20, IERC20Metadata, ERC20ABIDispatcher, ERC20ABIDispatcherTrait
    };
    use starknet::{
        ContractAddress, contract_address_const, get_contract_address, get_caller_address,
        get_tx_info, get_block_timestamp
    };

    use unruggable::errors;
    use unruggable::exchanges::jediswap_adapter::JediswapComponent;
    use unruggable::exchanges::jediswap_adapter::{
        IJediswapFactoryDispatcher, IJediswapFactoryDispatcherTrait, IJediswapRouterDispatcher,
        IJediswapRouterDispatcherTrait
    };
    use unruggable::exchanges::{Exchange, SupportedExchanges, ExchangeTrait};
    use unruggable::factory::{IFactory, IFactoryDispatcher, IFactoryDispatcherTrait};
    use unruggable::locker::{ITokenLockerDispatcher, ITokenLockerDispatcherTrait};
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

    component!(path: JediswapComponent, storage: jediswap, event: JediswapEvent);
    impl JediswapAdapterImpl = JediswapComponent::JediswapAdapterImpl<ContractState>;

    // Constants.
    /// The maximum number of holders allowed before launch.
    /// This is to prevent the contract from being launched with a large number of holders.
    /// Once reached, transfers are disabled until the memecoin is launched.
    const MAX_HOLDERS_BEFORE_LAUNCH: u8 = 10;
    /// The maximum percentage of the total supply that can be allocated to the team.
    /// This is to prevent the team from having too much control over the supply.
    const MAX_SUPPLY_PERCENTAGE_TEAM_ALLOCATION: u16 = 1_000; // 10%
    /// The maximum percentage of the supply that can be bought at once.
    const MAX_PERCENTAGE_BUY_LAUNCH: u8 = 200; // 2%

    const ETH_UNIT_DECIMALS: u256 = 1000000000000000000;


    #[storage]
    struct Storage {
        marker_v_0: (),
        launched: bool,
        pre_launch_holders_count: u8,
        team_allocation: u256,
        tx_hash_tracker: LegacyMap<ContractAddress, felt252>,
        locker_contract: ContractAddress,
        transfer_limit_delay: u64,
        launch_time: u64,
        factory_contract: ContractAddress,
        // Components.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        jediswap: JediswapComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        JediswapEvent: JediswapComponent::Event
    }

    /// Constructor called once when the contract is deployed.
    /// # Arguments
    /// * `owner` - The owner of the contract.
    /// * `locker_address` - Token locker address.
    /// * `transfer_limit_delay` - Delay timestamp to release transfer amount check.
    /// * `name` - The name of the token.
    /// * `symbol` - The symbol of the token.
    /// * `initial_supply` - The initial supply of the token.
    /// * `initial_holders` - The initial holders of the token, an array of holder_address
    /// * `initial_holders_amounts` - The initial amounts of tokens minted to the initial holders, an array of amounts
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        locker_address: ContractAddress,
        transfer_limit_delay: u64,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        initial_holders: Span<ContractAddress>,
        initial_holders_amounts: Span<u256>,
    ) {
        // Initialize the ERC20 token.
        self.erc20.initializer(name, symbol);

        // Initialize the owner.
        self.ownable.initializer(owner);

        // Initialize the token / internal logic
        let factory_address = get_caller_address();

        self
            .initializer(
                :locker_address,
                :factory_address,
                :transfer_limit_delay,
                :initial_supply,
                :initial_holders,
                :initial_holders_amounts
            );
    }

    //
    // External
    //
    #[abi(embed_v0)]
    impl UnruggableEntrypoints of IUnruggableAdditional<ContractState> {
        // ************************************
        // * UnruggableMemecoin functions
        // ************************************

        /// Launches Memecoin by creating a liquidity pool with the specified counterparty token using the Exchangev2 protocol.
        ///
        /// The owner must send tokens of the chosen counterparty (e.g., USDC) to launch Memecoin.
        ///
        /// # Arguments
        /// * `amm_v2`: SupportedExchanges to create a pair and send liquidity.
        /// * `liquidity_memecoin_amount`: The amount of Memecoin tokens to be provided as liquidity.
        /// * `liquidity_counterparty_token`: The amount of counterparty tokens to be provided as liquidity.
        /// * `deadline`: The deadline beyond which the operation will revert.
        ///
        /// # Panics
        /// This method will panic if:
        /// * The caller is not the owner of the contract.
        /// * Insufficient Memecoin funds are available for liquidity.
        /// * Insufficient counterparty token funds are available for liquidity.
        ///
        /// # Returns
        /// * `ContractAddress` - The contract address of the created liquidity pool.
        fn launch_memecoin(
            ref self: ContractState,
            amm_v2: SupportedExchanges,
            counterparty_token_address: ContractAddress,
        ) -> ContractAddress {
            // [Check Owner] Only the owner can launch the Memecoin
            self.ownable.assert_only_owner();

            let memecoin_address = starknet::get_contract_address();
            let caller_address = get_caller_address();
            let factory_address = self.factory_contract.read();

            let pair_address = match amm_v2 {
                SupportedExchanges::JediSwap => {
                    let router_address = IFactoryDispatcher { contract_address: factory_address }
                        .amm_router_address(amm_name: amm_v2.to_string());
                    let pair_address = self
                        .jediswap
                        .create_and_add_liquidity(
                            exchange_address: router_address,
                            token_address: memecoin_address,
                            counterparty_address: counterparty_token_address,
                            additional_parameters: array![].span(),
                        );
                    pair_address
                },
                SupportedExchanges::Ekubo => panic_with_felt252(errors::EXCHANGE_NOT_SUPPORTED)
            };

            // Launch the coin
            self.launched.write(true);
            self.launch_time.write(get_block_timestamp());

            // Renounce ownership of the memecoin
            self.ownable.renounce_ownership();

            pair_address
        }

        fn launched(self: @ContractState) -> bool {
            self.launched.read()
        }

        /// Returns the team allocation in tokens.
        fn get_team_allocation(self: @ContractState) -> u256 {
            self.team_allocation.read()
        }

        fn memecoin_factory_address(self: @ContractState) -> ContractAddress {
            self.factory_contract.read()
        }

        fn locker_address(self: @ContractState) -> ContractAddress {
            self.locker_contract.read()
        }
    }

    #[abi(embed_v0)]
    impl SnakeEntrypoints of IUnruggableMemecoinSnake<ContractState> {
        // ************************************
        // * snake_case functions
        // ************************************
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
            self.ensure_not_multicall(recipient);
            self.enforce_max_transfer_percentage(sender, recipient, amount);
            self.enforce_prelaunch_holders_limit(sender, recipient, amount);

            self.erc20.transfer(recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            // When we call launch_memecoin(), we invoke the add_liquidity() of the router,
            // which performs a transferFrom() to send the tokens to the pool.
            // Therefore, we need to bypass this validation if the sender is the memecoin contract.
            if sender != get_contract_address() {
                self.ensure_not_multicall(recipient);
                self.enforce_max_transfer_percentage(sender, recipient, amount);
                self.enforce_prelaunch_holders_limit(sender, recipient, amount);
            }
            self.erc20.transfer_from(sender, recipient, amount);
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
        // Initializes the state of the memecoin contract.
        ///
        /// This function sets the locker and factory contract addresses, enables a transfer limit delay,
        /// checks and allocates the team supply of the memecoin, and mints the remaining supply to the contract itself.
        ///
        /// # Arguments
        ///
        /// * `locker_address` - The address of the locker contract.
        /// * `factory_address` - The address of the factory contract.
        /// * `transfer_limit_delay` - The delay in seconds before transfers are no longer limited.
        /// * `initial_supply` - The initial supply of the memecoin.
        /// * `initial_holders` - A span of addresses that will hold the memecoin initially.
        /// * `initial_holders_amounts` - A span of amounts corresponding to the initial holders.
        ///
        fn initializer(
            ref self: ContractState,
            locker_address: ContractAddress,
            factory_address: ContractAddress,
            transfer_limit_delay: u64,
            initial_supply: u256,
            initial_holders: Span<ContractAddress>,
            initial_holders_amounts: Span<u256>
        ) {
            // Internal Registry
            self.locker_contract.write(locker_address);
            self.factory_contract.write(factory_address);

            // Enable a transfer limit - until this time has passed,
            // transfers are limited to a certain amount.
            self.transfer_limit_delay.write(transfer_limit_delay);

            let team_allocation = self
                .check_and_allocate_team_supply(
                    :initial_supply, :initial_holders, :initial_holders_amounts
                );

            // Mint remaining supply to the contract
            self
                .erc20
                ._mint(recipient: get_contract_address(), amount: initial_supply - team_allocation);
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
            let launch_time = self.launch_time.read();
            let transfer_delay = self.transfer_limit_delay.read();
            let current_time = get_block_timestamp();

            if (current_time < (launch_time + transfer_delay) || launch_time == 0_u64) {
                let tx_hash: felt252 = get_tx_info().unbox().transaction_hash;
                assert(self.tx_hash_tracker.read(recipient) != tx_hash, 'Multi calls not allowed');
                self.tx_hash_tracker.write(recipient, tx_hash);
            }
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
            if self.launched.read() {
                return;
            }

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


        /// Enforces the maximum transfer percentage during the launch phase.
        ///
        /// Checks if the coin has launched and if the transfer limit delay has passed.
        /// If not, it checks if the sender or recipient is the locker contract.
        /// If neither is the locker contract, it asserts that the transfer amount does not exceed a certain percentage of the total supply.
        ///
        /// # Arguments
        ///
        /// * `sender` - The address of the sender.
        /// * `recipient` - The address of the recipient.
        /// * `amount` - The amount to be transferred.
        ///
        /// # Panics
        ///
        /// * If the transfer amount exceeds the maximum allowed percentage of the total supply during the launch phase.
        ///
        //TODO: verify compatibility with LP pool. If lp calls `transferFrom` this might fail.
        // Not sure why the pool is whitelisted
        #[inline(always)]
        fn enforce_max_transfer_percentage(
            self: @ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
        ) {
            let launch_time = self.launch_time.read();
            let transfer_limit_delay = self.transfer_limit_delay.read();
            let current_time = get_block_timestamp();
            let locker_address = self.locker_contract.read();

            // Skip if the coin is launched and the transfer limit delay has passed
            if (launch_time != 0_u64 && current_time >= (launch_time + transfer_limit_delay)) {
                return;
            }

            // Skip if the sender or recipient is the locker contract
            if (sender == locker_address || recipient == locker_address) {
                return;
            }

            assert(
                amount <= self.total_supply().percent_mul(MAX_PERCENTAGE_BUY_LAUNCH.into()),
                'Max buy cap reached'
            )
        }
    }
}
