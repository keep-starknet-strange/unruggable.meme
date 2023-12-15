use starknet::ContractAddress;

#[starknet::interface]
trait IUnruggableMemecoinFactory<TContractState> {
    fn create_memecoin(
        ref self: TContractState,
        owner: ContractAddress,
        initial_recipient: ContractAddress,
        name: felt252,
        symbol: felt252,
        initial_supply: u256
    ) -> ContractAddress;
}

#[starknet::contract]
mod UnruggableMemecoinFactory {
    use core::box::BoxTrait;
    use super::IUnruggableMemecoinFactory;

    // Core dependencies.
    use poseidon::poseidon_hash_span;
    use starknet::SyscallResultTrait;
    use starknet::syscalls::deploy_syscall;
    use starknet::{
        ContractAddress, ClassHash, get_caller_address, get_contract_address, contract_address_const
    };

    // External dependencies.
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
    use openzeppelin::access::ownable::OwnableComponent;

    // Components.
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    use unruggablememecoin::amm::amm::AMM;

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
        amms: Array<AMM>
    ) {
        // Initialize the owner.
        self.ownable.initializer(owner);
        self.memecoin_class_hash.write(memecoin_class_hash);

        let mut i = 0;
        let amms_len = amms.len();
        loop {
            if amms_len == i {
                break;
            }
            let amm = *amms[i];
            self.amms.write(i, amm);
            i += 1;
        };
        self.amms_len.write(amms_len);
    }

    #[external(v0)]
    impl UnruggableMemeCoinFactoryImpl of IUnruggableMemecoinFactory<ContractState> {
        fn create_memecoin(
            ref self: ContractState,
            owner: ContractAddress,
            initial_recipient: ContractAddress,
            name: felt252,
            symbol: felt252,
            initial_supply: u256
        ) -> ContractAddress {
            let contract_address_salt = generate_salt(owner, name, symbol);

            // General calldata
            let mut calldata = serialize_calldata(
                owner, initial_recipient, name, symbol, initial_supply
            );

            Serde::serialize(@self.whitelisted_amms().into(), ref calldata);

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
        fn whitelisted_amms(self: @ContractState) -> Array<AMM> {
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
            amms
        }
    }

    fn serialize_calldata(
        owner: ContractAddress,
        initial_recipient: ContractAddress,
        name: felt252,
        symbol: felt252,
        initial_supply: u256
    ) -> Array<felt252> {
        let mut calldata = array![];
        calldata.append(owner.into());
        calldata.append(initial_recipient.into());
        calldata.append(name.into());
        calldata.append(symbol.into());
        Serde::serialize(@initial_supply, ref calldata);

        calldata
    }

    fn generate_salt(owner: ContractAddress, name: felt252, symbol: felt252) -> felt252 {
        let mut data = array![];
        data.append(owner.into());
        data.append(name.into());
        data.append(symbol.into());
        data.append(starknet::get_block_timestamp().into());
        poseidon_hash_span(data.span())
    }
}
