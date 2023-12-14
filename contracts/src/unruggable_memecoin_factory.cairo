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

    use unruggablememecoin::amm::amm::{AMMRouter, AMM, Network};

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
        network: felt252
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        network: felt252,
        memecoin_class_hash: ClassHash
    ) {
        // Initialize the owner.
        self.ownable.initializer(owner);
        self.memecoin_class_hash.write(memecoin_class_hash);

        // TODO: validate that its a valid Network
        self.network.write(network);
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

            let amms = self.get_whitelisted_amms();
            Serde::serialize(@amms.into(), ref calldata);

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
        fn get_whitelisted_amms(self: @ContractState) -> Array<AMMRouter> {
            let mut amms = array![];
            let tx_info = starknet::get_tx_info();
            let network: Network = self.network.read().try_into().expect('cannot convert network');

            // TODO: Complete others networks amms
            match network {
                Network::Mainnet => amms,
                Network::Goerli => amms,
                Network::Sepolia => amms,
                Network::Local => {
                    amms
                        .append(
                            AMMRouter {
                                name: AMM::JediSwap.into(),
                                address: contract_address_const::<
                                    0x17f2e8d48625c8f615a19a57b62d0a68b7096b0c51907daa8c8690458e6fb55
                                // 0x7eef7d58a3bad23287f9aacb4749e2a5de5af88c4b9a968eb5ce81937da62de
                                >()
                            }
                        );
                    amms
                },
            }
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
