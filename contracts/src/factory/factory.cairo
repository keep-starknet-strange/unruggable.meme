use openzeppelin::token::erc20::interface::{IERC20, ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use starknet::ContractAddress;

#[starknet::contract]
mod Factory {
    use core::box::BoxTrait;
    use core::starknet::event::EventEmitter;
    use core::zeroable::Zeroable;
    use ekubo::types::i129::i129;
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
    use unruggable::exchanges::ekubo::launcher::{
        IEkuboLauncherDispatcher, IEkuboLauncherDispatcherTrait
    };
    use unruggable::exchanges::{
        SupportedExchanges, ekubo_adapter, ekubo_adapter::EkuboPoolParameters, jediswap_adapter,
        jediswap_adapter::JediswapAdditionalParameters, ekubo::launcher::EkuboLP
    };
    use unruggable::factory::{IFactory, LaunchParameters};
    use unruggable::token::UnruggableMemecoin::LiquidityType;
    use unruggable::token::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };
    use unruggable::utils::math::PercentageMath;
    use unruggable::utils::unique_count;

    /// The maximum percentage of the total supply that can be allocated to the team.
    /// This is to prevent the team from having too much control over the supply.
    const MAX_SUPPLY_PERCENTAGE_TEAM_ALLOCATION: u16 = 1_000; // 10%

    /// The maximum number of holders one can specify when launching.
    /// This is to prevent the contract from being is_launched with a large number of holders.
    /// Once reached, transfers are disabled until the memecoin is is_launched.
    const MAX_HOLDERS_LAUNCH: u8 = 10;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MemecoinCreated: MemecoinCreated,
        MemecoinLaunched: MemecoinLaunched,
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
        quote_token: ContractAddress,
        exchange_name: felt252,
    }


    #[storage]
    struct Storage {
        memecoin_class_hash: ClassHash,
        exchange_configs: LegacyMap<SupportedExchanges, ContractAddress>,
        deployed_memecoins: LegacyMap<ContractAddress, bool>,
        lock_manager_address: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        memecoin_class_hash: ClassHash,
        lock_manager_address: ContractAddress,
        mut exchanges: Span<(SupportedExchanges, ContractAddress)>
    ) {
        self.memecoin_class_hash.write(memecoin_class_hash);
        self.lock_manager_address.write(lock_manager_address);

        // Add Exchanges configurations
        loop {
            match exchanges.pop_front() {
                Option::Some((exchange, address)) => self
                    .exchange_configs
                    .write(*exchange, *address),
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
            contract_address_salt: felt252,
        ) -> ContractAddress {
            let mut calldata = array![owner.into(), name.into(), symbol.into()];
            Serde::serialize(@initial_supply, ref calldata);

            let (memecoin_address, _) = deploy_syscall(
                self.memecoin_class_hash.read(), contract_address_salt, calldata.span(), false
            )
                .unwrap_syscall();

            // save memecoin address
            self.deployed_memecoins.write(memecoin_address, true);

            self.emit(MemecoinCreated { owner, name, symbol, initial_supply, memecoin_address });

            memecoin_address
        }

        fn launch_on_jediswap(
            ref self: ContractState,
            launch_parameters: LaunchParameters,
            quote_amount: u256,
            unlock_time: u64,
        ) -> ContractAddress {
            let (team_alloc, pre_holders) = check_common_launch_parameters(
                @self, launch_parameters
            );
            let router_address = self.exchange_address(SupportedExchanges::Jediswap);
            assert(router_address.is_non_zero(), errors::EXCHANGE_ADDRESS_ZERO);

            let LaunchParameters{memecoin_address,
            transfer_restriction_delay,
            max_percentage_buy_launch,
            quote_address,
            initial_holders,
            initial_holders_amounts } =
                launch_parameters;

            let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };
            let mut pair_address = jediswap_adapter::JediswapAdapterImpl::create_and_add_liquidity(
                exchange_address: router_address,
                token_address: memecoin_address,
                quote_address: quote_address,
                lp_supply: memecoin.total_supply() - team_alloc,
                additional_parameters: JediswapAdditionalParameters {
                    lock_manager_address: self.lock_manager_address.read(),
                    unlock_time,
                    quote_amount
                }
            );

            //TODO Write the team alloc in storage of the memecoin.
            // self.team_allocation.write(team_allocation);
            // self.pre_launch_holders_count.write(unique_count(initial_holders).try_into().unwrap());

            // Transfer the team's alloc
            distribute_team_alloc(memecoin, initial_holders, initial_holders_amounts);

            memecoin
                .set_launched(
                    LiquidityType::JediERC20(pair_address),
                    :transfer_restriction_delay,
                    :max_percentage_buy_launch
                );
            self
                .emit(
                    MemecoinLaunched {
                        memecoin_address, quote_token: quote_address, exchange_name: 'Jediswap'
                    }
                );
            pair_address
        }

        fn launch_on_ekubo(
            ref self: ContractState,
            launch_parameters: LaunchParameters,
            ekubo_parameters: EkuboPoolParameters,
        ) -> (u64, EkuboLP) {
            let (team_alloc, pre_holders) = check_common_launch_parameters(
                @self, launch_parameters
            );

            let LaunchParameters{memecoin_address,
            transfer_restriction_delay,
            max_percentage_buy_launch,
            quote_address,
            initial_holders,
            initial_holders_amounts } =
                launch_parameters;

            let launchpad_address = self.exchange_address(SupportedExchanges::Ekubo);
            assert(launchpad_address.is_non_zero(), errors::EXCHANGE_ADDRESS_ZERO);
            assert(ekubo_parameters.starting_tick.mag.is_non_zero(), errors::PRICE_ZERO);

            let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };
            let (id, position) = ekubo_adapter::EkuboAdapterImpl::create_and_add_liquidity(
                exchange_address: launchpad_address,
                token_address: memecoin_address,
                quote_address: quote_address,
                lp_supply: memecoin.total_supply() - team_alloc,
                additional_parameters: ekubo_parameters
            );

            // TODO: write team alloc and unique holders in memecoin
            distribute_team_alloc(memecoin, initial_holders, initial_holders_amounts);
            memecoin
                .set_launched(
                    LiquidityType::EkuboNFT(id),
                    :transfer_restriction_delay,
                    :max_percentage_buy_launch
                );
            self
                .emit(
                    MemecoinLaunched {
                        memecoin_address, quote_token: quote_address, exchange_name: 'Ekubo'
                    }
                );
            (id, position)
        }

        fn locked_liquidity(
            self: @ContractState, token: ContractAddress
        ) -> Option<(ContractAddress, LiquidityType)> {
            let memecoin = IUnruggableMemecoinDispatcher { contract_address: token };
            let liquidity_type = match memecoin.liquidity_type() {
                Option::Some(liquidity_type) => liquidity_type,
                Option::None => { return Option::None; },
            };
            let locker_address = match liquidity_type {
                LiquidityType::JediERC20(pair_address) => {
                    // ERC20 tokens are locked inside an ERC20Tokens-Locker
                    self.lock_manager_address.read()
                },
                LiquidityType::EkuboNFT(id) => {
                    // Ekubo NFTs are locked inside the EkuboLauncher contract
                    self.exchange_address(SupportedExchanges::Ekubo)
                }
            };

            Option::Some((locker_address, liquidity_type))
        }

        fn exchange_address(self: @ContractState, exchange: SupportedExchanges) -> ContractAddress {
            self.exchange_configs.read(exchange)
        }

        fn is_memecoin(self: @ContractState, address: ContractAddress) -> bool {
            self.deployed_memecoins.read(address)
        }

        fn ekubo_core_address(self: @ContractState) -> ContractAddress {
            let launcher = IEkuboLauncherDispatcher {
                contract_address: self.exchange_address(SupportedExchanges::Ekubo)
            };

            launcher.ekubo_core_address()
        }
    }


    /// Checks the launch parameters and calculates the team allocation.
    ///
    /// This function checks that the memecoin and quote addresses are valid,
    /// that the caller is the owner of the memecoin,
    /// that the memecoin has not been launched,
    /// and that the lengths of the initial holders and their amounts are equal and do not exceed the maximum allowed.
    /// It then calculates the maximum team allocation as a percentage of the total supply,
    /// and iteratively adds the amounts of the initial holders to the team allocation,
    /// ensuring that the total allocation does not exceed the maximum.
    /// It finally returns the total team allocation and the count of unique initial holders.
    ///
    /// # Arguments
    ///
    /// * `self` - A reference to the ContractState struct.
    /// * `launch_parameters` - The parameters for the token launch.
    ///
    /// # Returns
    ///
    /// * `(u256, u8)` - The total amount of memecoin allocated to the team and the count of unique initial holders.
    ///
    /// # Panics
    ///
    /// * If the memecoin address is not a memecoin.
    /// * If the quote address is a memecoin.
    /// * If the caller is not the owner of the memecoin.
    /// * If the memecoin has been launched.
    /// * If the lengths of the initial holders and their amounts are not equal.
    /// * If the number of initial holders exceeds the maximum allowed.
    /// * If the total team allocation exceeds the maximum allowed.
    ///
    fn check_common_launch_parameters(
        self: @ContractState, launch_parameters: LaunchParameters
    ) -> (u256, u8) {
        let LaunchParameters{memecoin_address,
        transfer_restriction_delay,
        max_percentage_buy_launch,
        quote_address,
        initial_holders,
        initial_holders_amounts } =
            launch_parameters;
        let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

        assert(self.is_memecoin(memecoin_address), errors::NOT_UNRUGGABLE);
        assert(!self.is_memecoin(quote_address), errors::QUOTE_TOKEN_IS_MEMECOIN);
        assert(!memecoin.is_launched(), errors::ALREADY_LAUNCHED);
        assert(get_caller_address() == memecoin.owner(), errors::CALLER_NOT_OWNER);
        assert(initial_holders.len() == initial_holders_amounts.len(), errors::ARRAYS_LEN_DIF);
        assert(initial_holders.len() <= MAX_HOLDERS_LAUNCH.into(), errors::MAX_HOLDERS_REACHED);

        let initial_supply = memecoin.total_supply();

        // Check that the sum of the amounts of initial holders does not exceed the max allocatable supply for a team.
        let max_team_allocation = initial_supply
            .percent_mul(MAX_SUPPLY_PERCENTAGE_TEAM_ALLOCATION.into());
        let mut team_allocation: u256 = 0;
        let mut i: usize = 0;
        loop {
            if i == initial_holders.len() {
                break;
            }

            let address = *initial_holders.at(i);
            let amount = *initial_holders_amounts.at(i);

            team_allocation += amount;
            assert(team_allocation <= max_team_allocation, errors::MAX_TEAM_ALLOCATION_REACHED);
            i += 1;
        };

        (team_allocation, unique_count(initial_holders).try_into().unwrap())
    }

    fn distribute_team_alloc(
        memecoin: IUnruggableMemecoinDispatcher,
        mut initial_holders: Span<ContractAddress>,
        mut initial_holders_amounts: Span<u256>
    ) {
        loop {
            match initial_holders.pop_front() {
                Option::Some(holder) => {
                    match initial_holders_amounts.pop_front() {
                        Option::Some(amount) => { memecoin.transfer(*holder, *amount); },
                        // Should never happen as the lengths of the spans are equal.
                        Option::None => { break; }
                    }
                },
                Option::None => { break; }
            }
        }
    }
}
