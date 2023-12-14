//! `UnruggableMemecoin` is an ERC20 token has additional features to prevent rug pulls.
use starknet::ContractAddress;
use unruggablememecoin::amm::amm::AMM;

#[starknet::interface]
trait IUnruggableMemecoin<TState> {
    // ************************************
    // * Standard ERC20 functions
    // ************************************
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn decimals(self: @TState) -> u8;
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;
    // ************************************
    // * Additional functions
    // ************************************
    fn launch_memecoin(
        ref self: TState,
        amm: AMM,
        counterparty_token_address: ContractAddress,
        liquidity_memecoin_amount: u256,
        liquidity_counterparty_token: u256
    );
}

#[starknet::contract]
mod UnruggableMemecoin {
    // Core dependencies.
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
    use integer::BoundedInt;
    use starknet::{ContractAddress, get_caller_address, contract_address_const};
    use zeroable::Zeroable;

    // External dependencies.
    use openzeppelin::access::ownable::OwnableComponent;

    // Internal dependencies.
    use unruggablememecoin::amm::amm::{AMMRouter, AMM};
    use unruggablememecoin::amm::jediswap_interface::{
        IFactoryC1Dispatcher, IFactoryC1DispatcherTrait, IRouterC1Dispatcher,
        IRouterC1DispatcherTrait, IERC20Dispatcher, IERC20DispatcherTrait
    };
    use super::IUnruggableMemecoin;

    use debug::PrintTrait;

    // Components.
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Constants.
    const DECIMALS: u8 = 18;
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
        name: felt252,
        symbol: felt252,
        total_supply: u256,
        balances: LegacyMap<ContractAddress, u256>,
        allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        // Components.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        amm_configs: LegacyMap<felt252, ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        value: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        value: u256
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
        amm_routers: Array<AMMRouter>
    ) {
        // [Check Owner] Only the Memecoin factory can deploy
        // assert get_caller_address() == memecoin_factory_address

        // Initialize the ERC20 token.
        self.initializer(name, symbol);

        let mut i = 0;
        loop {
            if amm_routers.len() == i {
                break;
            }
            let amm_router = *amm_routers[i];
            self.amm_configs.write(amm_router.name, amm_router.address);
            i += 1;
        };

        // Initialize the owner.
        self.ownable.initializer(owner);

        // Mint initial supply to the initial recipient.
        self._mint(initial_recipient, initial_supply);
    }

    //
    // External
    //
    #[abi(embed_v0)]
    impl UnruggableMemecoinImpl of IUnruggableMemecoin<ContractState> {
        // ************************************
        // * UnruggableMemecoin functions
        // ************************************

        /// Launches the Memecoin by creating a liquidity pool with the specified counterparty token.
        /// The owner needs to send both MT tokens and the tokens of the chosen counterparty (e.g., USDC).
        ///
        /// # Arguments
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
            amm: AMM,
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
                contract_address: self.amm_configs.read(amm.into()),
            };

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
            // TODO: this approve should be memecoin_address to router_address but test its failing
            self._approve(memecoin_address, caller_address, liquidity_memecoin_amount);
            counterparty_token_dispatcher
                .approve(amm_router.contract_address, liquidity_counterparty_token);

            'router launch()'.print();
            amm_router.contract_address.print();
            'memecoin launch()'.print();
            memecoin_address.print();

            'allowance token 1'.print();
            self.allowance(memecoin_address, amm_router.contract_address).print();

            'allowance token 2'.print();
            counterparty_token_dispatcher
                .allowance(memecoin_address, amm_router.contract_address)
                .print();

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

        // ************************************
        // * Standard ERC20 functions
        // ************************************
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            DECIMALS
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowances.read((owner, spender))
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
            'transfer_from memecoin'.print();
            let caller = get_caller_address();
            self._spend_allowance(sender, caller, amount);
            self._transfer(sender, recipient, amount);
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            self._approve(caller, spender, amount);
            true
        }
    }

    #[external(v0)]
    fn increase_allowance(
        ref self: ContractState, spender: ContractAddress, added_value: u256
    ) -> bool {
        self._increase_allowance(spender, added_value)
    }

    #[external(v0)]
    fn increaseAllowance(
        ref self: ContractState, spender: ContractAddress, addedValue: u256
    ) -> bool {
        increase_allowance(ref self, spender, addedValue)
    }

    #[external(v0)]
    fn decrease_allowance(
        ref self: ContractState, spender: ContractAddress, subtracted_value: u256
    ) -> bool {
        self._decrease_allowance(spender, subtracted_value)
    }

    #[external(v0)]
    fn decreaseAllowance(
        ref self: ContractState, spender: ContractAddress, subtractedValue: u256
    ) -> bool {
        decrease_allowance(ref self, spender, subtractedValue)
    }

    //
    // Internal
    //

    #[generate_trait]
    impl UnruggableMemecoinInternalImpl of UnruggableMemecoinInternalTrait {
        fn initializer(ref self: ContractState, name_: felt252, symbol_: felt252) {
            self.name.write(name_);
            self.symbol.write(symbol_);
        }

        fn _increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) -> bool {
            let caller = get_caller_address();
            self._approve(caller, spender, self.allowances.read((caller, spender)) + added_value);
            true
        }

        fn _decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u256
        ) -> bool {
            let caller = get_caller_address();
            self
                ._approve(
                    caller, spender, self.allowances.read((caller, spender)) - subtracted_value
                );
            true
        }

        fn _mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            assert(!recipient.is_zero(), 'ERC20: mint to 0');
            self.total_supply.write(self.total_supply.read() + amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            self.emit(Transfer { from: Zeroable::zero(), to: recipient, value: amount });
        }

        fn _burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            assert(!account.is_zero(), 'ERC20: burn from 0');
            self.total_supply.write(self.total_supply.read() - amount);
            self.balances.write(account, self.balances.read(account) - amount);
            self.emit(Transfer { from: account, to: Zeroable::zero(), value: amount });
        }

        fn _approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!owner.is_zero(), 'ERC20: approve from 0');
            assert(!spender.is_zero(), 'ERC20: approve to 0');
            self.allowances.write((owner, spender), amount);
            self.emit(Approval { owner, spender, value: amount });
        }

        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            assert(!sender.is_zero(), 'ERC20: transfer from 0');
            assert(!recipient.is_zero(), 'ERC20: transfer to 0');
            self.balances.write(sender, self.balances.read(sender) - amount);
            self.balances.write(recipient, self.balances.read(recipient) + amount);
            self.emit(Transfer { from: sender, to: recipient, value: amount });
        }

        fn _spend_allowance(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            let current_allowance = self.allowances.read((owner, spender));
            'owner'.print();
            owner.print();
            'spender'.print();
            spender.print();
            'current_allowance'.print();
            current_allowance.print();
            if current_allowance != BoundedInt::max() {
                self._approve(owner, spender, current_allowance - amount);
            }
        }
    }
}
