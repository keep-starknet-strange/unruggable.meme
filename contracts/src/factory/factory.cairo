use openzeppelin::token::erc20::interface::{IERC20, ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use starknet::ContractAddress;

#[starknet::contract]
mod Factory {
    use core::box::BoxTrait;
    use core::starknet::event::EventEmitter;
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
    use unruggable::errors;
    use unruggable::exchanges::{
        SupportedExchanges, ekubo_adapter, ekubo_adapter::EkuboAdditionalParameters,
        jediswap_adapter, jediswap_adapter::JediswapAdditionalParameters
    };
    use unruggable::factory::IFactory;
    use unruggable::tokens::UnruggableMemecoin::LiquidityPosition;
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    // Components.
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MemecoinCreated: MemecoinCreated,
        MemecoinLaunched: MemecoinLaunched,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct MemecoinCreated {
        owner: ContractAddress,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        memecoin_address: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct MemecoinLaunched {
        memecoin_address: ContractAddress,
        counterparty_token: ContractAddress,
        exchange_name: felt252,
    }

    #[storage]
    struct Storage {
        memecoin_class_hash: ClassHash,
        amm_configs: LegacyMap<SupportedExchanges, ContractAddress>,
        //TODO: refactor to keep a list of deployed memecoins and expose it publicly
        deployed_memecoins: LegacyMap<ContractAddress, bool>,
        lock_manager_address: ContractAddress,
        // Components.
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        memecoin_class_hash: ClassHash,
        lock_manager_address: ContractAddress,
        mut amms: Span<(SupportedExchanges, ContractAddress)>
    ) {
        self.ownable.initializer(owner);
        self.memecoin_class_hash.write(memecoin_class_hash);
        self.lock_manager_address.write(lock_manager_address);

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
                owner.into(), transfer_limit_delay.into(), name.into(), symbol.into()
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

            self.emit(MemecoinCreated { owner, name, symbol, initial_supply, memecoin_address });

            memecoin_address
        }

        fn launch_on_jediswap(
            ref self: ContractState,
            memecoin_address: ContractAddress,
            counterparty_address: ContractAddress,
            counterparty_amount: u256,
            unlock_time: u64,
        ) -> ContractAddress {
            let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };
            assert(!memecoin.is_launched(), errors::ALREADY_LAUNCHED);
            assert(get_caller_address() == memecoin.owner(), errors::CALLER_NOT_OWNER);
            let counterparty_token = ERC20ABIDispatcher { contract_address: counterparty_address };
            let caller_address = get_caller_address();

            let router_address = self.exchange_address(SupportedExchanges::Jediswap);
            let mut pair_address = jediswap_adapter::JediswapAdapterImpl::create_and_add_liquidity(
                exchange_address: router_address,
                token_address: memecoin_address,
                counterparty_address: counterparty_address,
                additional_parameters: JediswapAdditionalParameters {
                    lock_manager_address: self.lock_manager_address(),
                    unlock_time,
                    counterparty_amount
                }
            );

            memecoin.set_launched(LiquidityPosition::ERC20(pair_address));
            self
                .emit(
                    MemecoinLaunched {
                        memecoin_address,
                        counterparty_token: counterparty_address,
                        exchange_name: 'Jediswap'
                    }
                );
            pair_address
        }

        fn launch_on_ekubo(
            ref self: ContractState,
            memecoin_address: ContractAddress,
            counterparty_address: ContractAddress,
            fee: u128,
            tick_spacing: u128,
            starting_tick: u128,
            bound: u128
        ) -> u64 {
            let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };
            assert(get_caller_address() == memecoin.owner(), errors::CALLER_NOT_OWNER);
            assert(!memecoin.is_launched(), 'memecoin already launched');
            let counterparty_token = ERC20ABIDispatcher { contract_address: counterparty_address };
            let caller_address = get_caller_address();
            let launchpad_address = self.exchange_address(SupportedExchanges::Ekubo);

            let ekubo_parameters = EkuboAdditionalParameters {
                fee, tick_spacing, starting_tick, bound,
            };

            let mut nft_id = ekubo_adapter::EkuboAdapterImpl::create_and_add_liquidity(
                exchange_address: launchpad_address,
                token_address: memecoin_address,
                counterparty_address: counterparty_address,
                additional_parameters: ekubo_parameters
            );

            memecoin.set_launched(LiquidityPosition::NFT(nft_id));
            self
                .emit(
                    MemecoinLaunched {
                        memecoin_address,
                        counterparty_token: counterparty_address,
                        exchange_name: 'Ekubo'
                    }
                );
            nft_id
        }

        fn lock_manager_address(self: @ContractState) -> ContractAddress {
            self.lock_manager_address.read()
        }

        fn exchange_address(self: @ContractState, amm: SupportedExchanges) -> ContractAddress {
            self.amm_configs.read(amm)
        }

        fn is_memecoin(self: @ContractState, address: ContractAddress) -> bool {
            self.deployed_memecoins.read(address)
        }
    }
}
