//! `UnruggableMemecoin` is an ERC20 token has additional features to prevent rug pulls.
use starknet::ContractAddress;

#[starknet::contract]
mod UnruggableMemecoin {
    use integer::BoundedInt;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
    use openzeppelin::token::erc20::ERC20Component;
    use starknet::{ContractAddress, get_caller_address};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinSnake, IUnruggableMemecoinCamel, IUnruggableAdditional
    };
    use unruggable::amm::jediswap_interface::{
        IFactoryC1Dispatcher, IFactoryC1DispatcherTrait, IRouterC1Dispatcher,
        IRouterC1DispatcherTrait, IERC20Dispatcher, IERC20DispatcherTrait
    };
    use unruggable::amm::amm::{AMM, AMMV2};
    use zeroable::Zeroable;

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
    const MAX_SUPPLY_PERCENTAGE_TEAM_ALLOCATION: u8 = 10;
    /// The maximum percentage of the supply that can be bought at once.
    const MAX_PERCENTAGE_BUY_LAUNCH: u8 = 2;

    #[storage]
    struct Storage {
        marker_v_0: (),
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


    /// Constructor called once when the contract is deployed.
    /// # Arguments
    /// * `owner` - The owner of the contract.
    /// * `initial_recipient` - The initial recipient of the initial supply.
    /// * `name` - The name of the token.
    /// * `symbol` - The symbol of the token.
    /// * `initial_supply` - The initial supply of the token.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        initial_recipient: ContractAddress,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        amms: Array<AMM>
    ) {
        // Initialize the ERC20 token.
        self.erc20.initializer(name, symbol);

        // Initialize the owner.
        self.ownable.initializer(owner);

        // Read configs from factory
        let mut i = 0;
        loop {
            if amms.len() == i {
                break;
            }
            let amm = *amms[i];
            self.amm_configs.write(amm.name, amm.router_address);
            i += 1;
        };

        // Mint initial supply to the initial recipient.
        self.erc20._mint(initial_recipient, initial_supply);
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
            let memecoin_balance = self.balance_of(memecoin_address);
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
        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            self.erc20._transfer(sender, recipient, amount);
        }

        fn _approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            self.erc20._approve(owner, spender, amount);
        }
    }
}
