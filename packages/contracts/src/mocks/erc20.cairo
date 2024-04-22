#[starknet::contract]
mod ERC20Token {
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::erc20::ERC20Component::InternalTrait;
    use starknet::ContractAddress;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnly = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_supply: u256, recipient: ContractAddress) {
        let name = 'MyToken';
        let symbol = 'MTK';

        self.erc20.initializer(name, symbol);
        self.erc20._mint(recipient, initial_supply);
    }

    /// Creates a `value` amount of tokens and assigns them to `account`.
    /// Emits a `Transfer` event with `from` set to the zero address.
    #[external(v0)]
    fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
        self.erc20._mint(recipient, amount);
    }
}
