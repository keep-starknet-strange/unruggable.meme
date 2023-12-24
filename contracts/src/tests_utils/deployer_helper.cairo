mod DeployerHelper {
    use snforge_std::{
        ContractClass, ContractClassTrait, CheatTarget, declare, start_prank, stop_prank
    };
    use starknet::{ContractAddress, ClassHash, contract_address_const};
    use unruggable::amm::amm::AMM;
    use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};

    const ETH_UNIT_DECIMALS: u256 = 1000000000000000000;

    fn deploy_contracts() -> (ContractAddress, ContractAddress) {
        let deployer = contract_address_const::<'DEPLOYER'>();
        let pair_class = declare('PairC1');

        let mut factory_constructor_calldata = Default::default();

        Serde::serialize(@pair_class.class_hash, ref factory_constructor_calldata);
        Serde::serialize(@deployer, ref factory_constructor_calldata);
        let factory_class = declare('FactoryC1');

        let factory_address = factory_class.deploy(@factory_constructor_calldata).unwrap();

        let mut router_constructor_calldata = Default::default();
        Serde::serialize(@factory_address, ref router_constructor_calldata);
        let router_class = declare('RouterC1');

        let router_address = router_class.deploy(@router_constructor_calldata).unwrap();

        (factory_address, router_address)
    }

    fn deploy_unruggable_memecoin_contract(
        owner: ContractAddress,
        recipient: ContractAddress,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        amms: Array<AMM>
    ) -> ContractAddress {
        let contract = declare('UnruggableMemecoin');
        let mut constructor_calldata = array![
            owner.into(),
            recipient.into(),
            name,
            symbol,
            initial_supply.low.into(),
            initial_supply.high.into(),
        ];
        contract.deploy(@constructor_calldata).unwrap()
    }

    fn deploy_memecoin_factory(
        owner: ContractAddress, memecoin_class_hash: ClassHash, amms: Array<AMM>
    ) -> ContractAddress {
        let contract = declare('UnruggableMemecoinFactory');
        let mut calldata = array![];
        calldata.append(owner.into());
        calldata.append(memecoin_class_hash.into());
        Serde::serialize(@amms.into(), ref calldata);

        contract.deploy(@calldata).unwrap()
    }

    fn create_eth(
        initial_supply: u256, owner: ContractAddress, factory: ContractAddress
    ) -> IERC20Dispatcher {
        let erc20_token = declare('ERC20Token');
        let eth_amount: u256 = initial_supply;
        let erc20_calldata: Array<felt252> = array![
            eth_amount.low.into(), eth_amount.high.into(), owner.into()
        ];
        let eth_address = erc20_token
            .deploy_at(
                @erc20_calldata,
                contract_address_const::<
                    0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
                >()
            )
            .unwrap();
        let eth = IERC20Dispatcher { contract_address: eth_address };
        assert(eth.balance_of(owner) == initial_supply, 'wrong eth balance');
        start_prank(CheatTarget::One(eth.contract_address), owner);
        eth.approve(spender: factory, amount: 1 * ETH_UNIT_DECIMALS);
        stop_prank(CheatTarget::One(eth.contract_address));
        assert(
            eth.allowance(:owner, spender: factory) == 1 * ETH_UNIT_DECIMALS, 'wrong eth allowance'
        );
        eth
    }
}
