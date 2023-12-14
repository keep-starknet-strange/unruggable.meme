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
        erc20: ERC20Component::Storage
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
        initial_supply: u256
    ) {
        // Initialize the ERC20 token.
        self.erc20.initializer(name, symbol);

        // Initialize the owner.
        self.ownable.initializer(owner);

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
        fn launch_memecoin(ref self: ContractState) {
            // Checks: Only the owner can launch the memecoin.
            self.ownable.assert_only_owner();
        // Effects.

        // Interactions.
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
            self._check_max_buy_percentage(amount);
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
            self._check_max_buy_percentage(amount);
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

        fn _check_max_buy_percentage(self: @ContractState, amount: u256) {
            assert(
                self.erc20.ERC20_total_supply.read()
                    * MAX_PERCENTAGE_BUY_LAUNCH.into()
                    / 100 >= amount,
                'Max buy cap reached'
            )
        }
    }
}
