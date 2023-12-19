use starknet::ContractAddress;

#[starknet::interface]
trait IUnruggableMemecoinFactory<TContractState> {
    fn create_memecoin(
        ref self: TContractState,
        owner: ContractAddress,
        initial_recipient: ContractAddress,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        initial_holders: Span<ContractAddress>,
        initial_holders_amounts: Span<u256>,
    ) -> ContractAddress;
}

#[starknet::contract]
mod UnruggableMemecoinFactory {
    use core::box::BoxTrait;
    use openzeppelin::access::ownable::OwnableComponent;

    // External dependencies.
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;

    // Core dependencies.
    use poseidon::poseidon_hash_span;
    use starknet::SyscallResultTrait;
    use starknet::syscalls::deploy_syscall;
    use starknet::{
        ContractAddress, ClassHash, get_caller_address, get_contract_address, contract_address_const
    };
    use super::IUnruggableMemecoinFactory;

    use unruggable::amm::amm::AMM;

    // Components.
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MemeCoinCreated: MemeCoinCreated,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct MemeCoinCreated {
        owner: ContractAddress,
        initial_recipient: ContractAddress,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        memecoin_address: ContractAddress
    }

    #[storage]
    struct Storage {
        // Components.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        memecoin_class_hash: ClassHash,
        amms: LegacyMap<u32, AMM>,
        amms_len: u32
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        memecoin_class_hash: ClassHash,
        mut amms: Span<AMM>
    ) {
        // Initialize the owner.
        self.ownable.initializer(owner);
        self.memecoin_class_hash.write(memecoin_class_hash);

        let mut i = 0;
        let amms_len = amms.len();
        loop {
            match amms.pop_front() {
                Option::Some(amm) => self.amms.write(i, *amm),
                Option::None => { break; }
            }
            i += 1;
        };
        self.amms_len.write(amms_len);
    }

    #[external(v0)]
    impl UnruggableMemeCoinFactoryImpl of IUnruggableMemecoinFactory<ContractState> {
        /// Deploys a new Memecoin smart contract instance with the specified parameters.
        ///
        /// # Arguments
        ///
        /// * `owner` - The address of the Memecoin contract owner.
        /// * `initial_recipient` - The initial recipient's address.
        /// * `name` - The name of the Memecoin.
        /// * `symbol` - The symbol of the Memecoin.
        /// * `initial_supply` - The initial supply of the Memecoin.
        ///
        /// # Returns
        ///
        /// The address of the newly created Memecoin smart contract.
        fn create_memecoin(
            ref self: ContractState,
            owner: ContractAddress,
            initial_recipient: ContractAddress,
            name: felt252,
            symbol: felt252,
            initial_supply: u256,
            initial_holders: Span<ContractAddress>,
            initial_holders_amounts: Span<u256>,
        ) -> ContractAddress {
            let contract_address_salt = generate_salt(owner, name, symbol);

            // General calldata
            let mut calldata = serialize_calldata(
                owner, initial_recipient, name, symbol, initial_supply
            );
            Serde::serialize(@self.whitelisted_amms().into(), ref calldata);
            Serde::serialize(@initial_holders.into(), ref calldata);
            Serde::serialize(@initial_holders_amounts.into(), ref calldata);

            let (memecoin_address, _) = deploy_syscall(
                self.memecoin_class_hash.read(), contract_address_salt, calldata.span(), false
            )
                .unwrap_syscall();

            self
                .emit(
                    MemeCoinCreated {
                        owner, name, symbol, initial_recipient, initial_supply, memecoin_address
                    }
                );
            memecoin_address
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        /// Returns a span containing the whitelisted Automated Market Makers (AMMs).
        ///
        /// # Returns
        ///
        /// A span containing a collection of whitelisted AMMs.
        fn whitelisted_amms(self: @ContractState) -> Span<AMM> {
            let mut amms = array![];
            let amms_len = self.amms_len.read();
            let mut i = 0;

            loop {
                if amms_len == i {
                    break;
                }
                amms.append(self.amms.read(i));
                i += 1;
            };

            amms.span()
        }
    }

    /// Serializes input parameters into calldata.
    ///
    /// # Arguments
    ///
    /// * `owner` - The address of the contract owner.
    /// * `initial_recipient` - The initial recipient's address.
    /// * `name` - The name of the contract.
    /// * `symbol` - The symbol of the contract.
    /// * `initial_supply` - The initial supply of the contract.
    ///
    /// # Returns
    ///
    /// An array containing the serialized calldata.
    fn serialize_calldata(
        owner: ContractAddress,
        initial_recipient: ContractAddress,
        name: felt252,
        symbol: felt252,
        initial_supply: u256
    ) -> Array<felt252> {
        let mut calldata = array![
            owner.into(), initial_recipient.into(), name.into(), symbol.into()
        ];
        Serde::serialize(@initial_supply, ref calldata);
        calldata
    }


    /// Generates a unique salt.
    ///
    /// # Arguments
    ///
    /// * `owner` - The address of the contract owner.
    /// * `name` - The name of the contract.
    /// * `symbol` - The symbol of the contract.
    ///
    /// # Returns
    ///
    /// A unique salt value (felt252) for contract function execution.
    fn generate_salt(owner: ContractAddress, name: felt252, symbol: felt252) -> felt252 {
        let mut data = array![
            owner.into(), name.into(), symbol.into(), starknet::get_block_timestamp().into()
        ];
        poseidon_hash_span(data.span())
    }
}
