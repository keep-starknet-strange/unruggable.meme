//! `UnruggableMemecoin` is an ERC20 token has additional features to prevent rug pulls.
use starknet::ContractAddress;

#[starknet::contract]
mod UnruggableMemecoin {
    use array::ArrayTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{
        ContractAddress, contract_address_const, get_contract_address, get_caller_address
    };
    use unruggable::amm::amm::{AMM, AMMV2};
    use unruggable::amm::jediswap_interface::{
        IFactoryC1Dispatcher, IFactoryC1DispatcherTrait, IRouterC1Dispatcher,
        IRouterC1DispatcherTrait
    };
    use unruggable::tokens::interface::{
        IUnruggableMemecoinSnake, IUnruggableMemecoinCamel, IUnruggableAdditional
    };

    // Components.
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    // Internals
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    // ERC20 entrypoints.
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;

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

    #[storage]
    struct Storage {
        marker_v_0: (),
        launched: bool,
        pre_launch_holders_count: u8,
        team_allocation: u256,
        locker_contract: ContractAddress,
        // Components.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        amm_configs: LegacyMap<felt252, ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    mod Errors {
        const MAX_HOLDERS_REACHED: felt252 = 'Unruggable: max holders reached';
        const ARRAYS_LEN_DIF: felt252 = 'Unruggable: arrays len dif';
        const MAX_TEAM_ALLOCATION_REACHED: felt252 = 'Unruggable: max team allocation';
    }


    /// Constructor called once when the contract is deployed.
    /// # Arguments
    /// * `owner` - The owner of the contract.
    /// * `initial_recipient` - The initial recipient of the initial supply.
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
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        mut amms: Span<AMM>,
        initial_holders: Span<ContractAddress>,
        initial_holders_amounts: Span<u256>,
    ) {
        // Initialize the ERC20 token.
        self.erc20.initializer(name, symbol);

        // Initialize the owner.
        self.ownable.initializer(owner);

        // Add AMMs configurations
        loop {
            match amms.pop_front() {
                Option::Some(amm) => self.amm_configs.write(*amm.name, *amm.router_address),
                Option::None => { break; }
            }
        };

        // Initialize the token / internal logic
        self
            ._initializer(
                locker_address, :initial_supply, :initial_holders, :initial_holders_amounts
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

        /// Launches Memecoin by creating a liquidity pool with the specified counterparty token using the AMMv2 protocol.
        /// The owner must send both MT tokens (Memecoin) and tokens of the chosen counterparty (e.g., USDC) to launch memecoin.
        ///
        /// # Arguments
        /// - `amm_v2`: AMMV2 to create pair and send liquidity
        /// - `counterparty_token_address`: The contract address of the counterparty token.
        /// - `liquidity_memecoin_amount`: The amount of Memecoin tokens to be provided as liquidity.
        /// - `liquidity_counterparty_token`: The amount of counterparty tokens to be provided as liquidity.
        ///
        /// # Panics
        /// This method will panic if:
        /// - The caller is not the owner of the contract.
        /// - Insufficient Memecoin funds are available for liquidity.
        /// - Insufficient counterparty token funds are available for liquidity.
        fn launch_memecoin(
            ref self: ContractState,
            amm_v2: AMMV2,
            counterparty_token_address: ContractAddress,
            liquidity_memecoin_amount: u256,
            liquidity_counterparty_token: u256,
        ) {
            // [Check Owner] Only the owner can launch the Memecoin
            self.ownable.assert_only_owner();

            let memecoin_address = starknet::get_contract_address();
            let caller_address = get_caller_address();

            // [Create Pool]
            let amm_router = IRouterC1Dispatcher {
                contract_address: self.amm_configs.read(amm_v2.into()),
            };
            assert(amm_router.contract_address.is_non_zero(), 'AMM not supported');

            let amm_factory = IFactoryC1Dispatcher { contract_address: amm_router.factory(), };
            let pair_address = amm_factory
                .create_pair(counterparty_token_address, memecoin_address);

            // [Check Balance]
            let memecoin_balance = self.balanceOf(memecoin_address);
            let counterparty_token_dispatcher = IERC20Dispatcher {
                contract_address: counterparty_token_address,
            };
            let counterparty_token_balance = counterparty_token_dispatcher
                .balance_of(memecoin_address);

            assert(memecoin_balance >= liquidity_memecoin_amount, 'insufficient memecoin funds');
            assert(
                counterparty_token_balance >= liquidity_counterparty_token,
                'insufficient token funds',
            );

            // [Approve]
            self._approve(memecoin_address, amm_router.contract_address, liquidity_memecoin_amount);
            counterparty_token_dispatcher
                .approve(amm_router.contract_address, liquidity_counterparty_token);

            // [Add liquidity]
            amm_router
                .add_liquidity(
                    memecoin_address,
                    counterparty_token_address,
                    liquidity_memecoin_amount,
                    liquidity_counterparty_token,
                    1, // amount_a_min
                    1, // amount_b_min
                    memecoin_address,
                    0, // deadline
                );

            // Launch the coin
            self.launched.write(true);
        }

        fn launched(self: @ContractState) -> bool {
            self.launched.read()
        }

        /// Returns the team allocation in tokens.
        fn get_team_allocation(self: @ContractState) -> u256 {
            self.team_allocation.read()
        }
    }

    #[abi(embed_v0)]
    impl SnakeEntrypoints of IUnruggableMemecoinSnake<ContractState> {
        // ************************************
        // * snake_case functions
        // ************************************
        fn total_supply(self: @ContractState) -> u256 {
            self.erc20.ERC20_total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.ERC20_balances.read(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.erc20.ERC20_allowances.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._check_max_buy_percentage(sender, recipient, amount);
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
            self._check_max_buy_percentage(sender, recipient, amount);
            self.erc20._spend_allowance(sender, caller, amount);
            self.erc20._transfer(sender, recipient, amount);
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            self.erc20._approve(caller, spender, amount);
            true
        }
    }

    #[abi(embed_v0)]
    impl CamelEntrypoints of IUnruggableMemecoinCamel<ContractState> {
        fn totalSupply(self: @ContractState) -> u256 {
            self.erc20.ERC20_total_supply.read()
        }
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.ERC20_balances.read(account)
        }
        fn transferFrom(
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
    }

    //
    // Internal
    //
    #[generate_trait]
    impl UnruggableMemecoinInternalImpl of UnruggableMemecoinInternalTrait {
        /// Internal function to enforce pre launch holder limit
        ///
        /// Note that when transfers are done, between addresses that already
        /// hold tokens, we do not increment the number of holders. it only
        /// gets incremented when the recipient that hold no tokens.
        /// But if the sender will no longer hold tokens after the transfer,
        /// the number of holders is decremented.
        ///
        /// # Arguments
        /// * `sender` - The sender of the tokens being transferred.
        /// * `recipient` - The recipient of the tokens being transferred.
        /// * `amount` - The amount of tokens being transferred.
        #[inline(always)]
        fn _enforce_holders_limit(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            if !self.launched.read() {
                // if the sender will no longer hold tokens
                if sender.is_non_zero() && self.balance_of(sender) == amount {
                    let current_holders_count = self.pre_launch_holders_count.read();

                    // decrease holders count
                    self.pre_launch_holders_count.write(current_holders_count - 1);
                }

                // if the recipient doesn't hold tokens yet
                if self.balance_of(recipient).is_zero() {
                    let current_holders_count = self.pre_launch_holders_count.read();

                    // assert max holders limit is not reached
                    assert(
                        current_holders_count < MAX_HOLDERS_BEFORE_LAUNCH,
                        Errors::MAX_HOLDERS_REACHED
                    );

                    // increase holders count
                    self.pre_launch_holders_count.write(current_holders_count + 1);
                }
            }
        }

        /// Internal function to mint tokens
        ///
        /// Before minting, a check is done to ensure that
        /// only `MAX_HOLDERS_BEFORE_LAUNCH` addresses can hold
        /// tokens if token hasn't launched
        ///
        /// # Arguments
        /// * `recipient` - The recipient of the tokens.
        /// * `amount` - The amount of tokens to be minted.
        fn _mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self._enforce_holders_limit(sender: contract_address_const::<0>(), :recipient, :amount);
            self.erc20._mint(recipient, amount);
        }

        /// Internal function to transfer tokens
        ///
        /// Before transferring, a check is done to ensure that
        /// only `MAX_HOLDERS_BEFORE_LAUNCH` addresses can hold
        /// tokens if token hasn't launched
        ///
        /// # Arguments
        /// * `sender` - The sender or owner of the tokens.
        /// * `recipient` - The recipient of the tokens.
        /// * `amount` - The amount of tokens to be transferred.
        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            self._enforce_holders_limit(:sender, :recipient, :amount);
            self.erc20._transfer(sender, recipient, amount);
        }

        /// Internal function to approve spending of tokens.
        ///
        /// # Arguments
        ///
        /// * `self` - A mutable reference to the contract state.
        /// * `owner` - The owner of the tokens.
        /// * `spender` - The address allowed to spend the tokens.
        /// * `amount` - The amount of tokens to be approved for spending.
        fn _approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            self.erc20._approve(owner, spender, amount);
        }

        /// Internal function to assert the buy limit is not reached
        ///
        /// This check ensure that an address cannot buy more
        /// than the maximum percentage of the supply that can
        /// be bought at once.
        ///
        /// # Arguments
        /// * `amount` - The amount of tokens being transferred.
        #[inline(always)]
        fn _check_max_buy_percentage(
            self: @ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
        ) {
            let locker_address = self.locker_contract.read();
            if (sender != locker_address && recipient != locker_address) {
                assert(
                    self.erc20.ERC20_total_supply.read()
                        * MAX_PERCENTAGE_BUY_LAUNCH.into()
                        / 10_000 >= amount,
                    'Max buy cap reached'
                )
            }
        }

        /// Constructor logic.
        /// # Arguments
        /// * `locker_address` - Token locker contract address.
        /// * `initial_supply` - The initial supply of the token.
        /// * `initial_holders` - The initial holders of the token, an array of holder_address
        /// * `initial_holders_amounts` - The initial amounts of tokens minted to the initial holders, an array of amounts
        fn _initializer(
            ref self: ContractState,
            locker_address: ContractAddress,
            initial_supply: u256,
            initial_holders: Span<ContractAddress>,
            initial_holders_amounts: Span<u256>
        ) {
            self.locker_contract.write(locker_address);
            let mut team_allocation: u256 = 0;
            let max_team_allocation = initial_supply
                * MAX_SUPPLY_PERCENTAGE_TEAM_ALLOCATION.into()
                / 10_000;
            let mut i: usize = 0;

            // check initial holders len match
            assert(initial_holders.len() == initial_holders_amounts.len(), Errors::ARRAYS_LEN_DIF);

            // check on max holders count
            assert(
                initial_holders.len() <= MAX_HOLDERS_BEFORE_LAUNCH.into(),
                Errors::MAX_HOLDERS_REACHED
            );

            loop {
                if i >= initial_holders.len() {
                    break;
                }

                let address = *initial_holders.at(i);
                let amount = *initial_holders_amounts.at(i);

                // increase team allocation
                team_allocation += amount;

                // check on max team allocation
                assert(team_allocation <= max_team_allocation, Errors::MAX_TEAM_ALLOCATION_REACHED);

                // mint to holder using the erc20 internal to avoid triggering pre launch safeguards and waste gas.
                self.erc20._mint(recipient: address, :amount);

                i += 1;
            };

            // mint remaining supply to the contract
            self
                .erc20
                ._mint(recipient: get_contract_address(), amount: initial_supply - team_allocation);

            // save team allocation
            self.team_allocation.write(team_allocation);

            // save pre launch holders count
            self.pre_launch_holders_count.write(initial_holders.len().try_into().unwrap());
        }
    }
}
