use openzeppelin::token::erc20::interface::{IERC20, ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use starknet::ContractAddress;

#[starknet::contract]
mod Factory {
    use core::box::BoxTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::ownable::OwnableComponent::InternalTrait;
    use openzeppelin::token::erc20::interface::{
        IERC20, ERC20ABIDispatcher, ERC20ABIDispatcherTrait
    };
    use poseidon::poseidon_hash_span;
    use starknet::SyscallResultTrait;
    use starknet::syscalls::deploy_syscall;
    use starknet::{
        ContractAddress, ClassHash, get_caller_address, get_contract_address, contract_address_const
    };
    use unruggable::exchanges::{SupportedExchanges};
    use unruggable::factory::IFactory;

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
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        memecoin_address: ContractAddress
    }

    const ETH_UNIT_DECIMALS: u256 = 1000000000000000000;

    #[storage]
    struct Storage {
        memecoin_class_hash: ClassHash,
        amm_configs: LegacyMap<SupportedExchanges, ContractAddress>,
        deployed_memecoins: LegacyMap<ContractAddress, bool>,
        // Components.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        memecoin_class_hash: ClassHash,
        mut amms: Span<(SupportedExchanges, ContractAddress)>
    ) {
        // Initialize the owner.
        self.ownable.initializer(owner);
        self.memecoin_class_hash.write(memecoin_class_hash);

        // Add Exchanges configurations
        loop {
            match amms.pop_front() {
                Option::Some((amm, address)) => self.amm_configs.write(*amm, *address),
                Option::None => { break; }
            }
        };
    }

    #[abi(embed_v0)]
    impl FactoryImpl of IFactory<ContractState> {
        fn create_memecoin(
            ref self: ContractState,
            owner: ContractAddress,
            lock_manager_address: ContractAddress,
            name: felt252,
            symbol: felt252,
            initial_supply: u256,
            initial_holders: Span<ContractAddress>,
            initial_holders_amounts: Span<u256>,
            transfer_limit_delay: u64,
            counterparty_token: ERC20ABIDispatcher,
            contract_address_salt: felt252,
        ) -> ContractAddress {
            let mut calldata = array![
                owner.into(),
                lock_manager_address.into(),
                transfer_limit_delay.into(),
                name.into(),
                symbol.into()
            ];
            Serde::serialize(@initial_supply, ref calldata);
            Serde::serialize(@initial_holders.into(), ref calldata);
            Serde::serialize(@initial_holders_amounts.into(), ref calldata);

            let (memecoin_address, _) = deploy_syscall(
                self.memecoin_class_hash.read(), contract_address_salt, calldata.span(), false
            )
                .unwrap_syscall();

            // save memecoin address
            self.deployed_memecoins.write(memecoin_address, true);

            let caller = get_caller_address();
            //TODO!(make the initial liquidity a parameter)
            let eth_amount: u256 = 1 * ETH_UNIT_DECIMALS;

            counterparty_token
                .transferFrom(sender: caller, recipient: memecoin_address, amount: eth_amount);
            self.emit(MemeCoinCreated { owner, name, symbol, initial_supply, memecoin_address });

            memecoin_address
        }

        fn exchange_address(self: @ContractState, amm: SupportedExchanges) -> ContractAddress {
            self.amm_configs.read(amm)
        }

        fn is_memecoin(self: @ContractState, address: ContractAddress) -> bool {
            self.deployed_memecoins.read(address)
        }
    }
}
