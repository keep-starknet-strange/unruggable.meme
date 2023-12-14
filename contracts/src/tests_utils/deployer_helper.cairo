mod DeployerHelper {
    use starknet::{ContractAddress, ClassHash};
    use snforge_std::{
        ContractClass, ContractClassTrait, CheatTarget, declare, start_prank, stop_prank
    };
    use unruggablememecoin::tests_utils::constants::{DEPLOYER, TOKEN0_NAME, SYMBOL};
    use unruggablememecoin::amm::amm::AMMRouter;

    fn deploy_contracts() -> (ContractAddress, ContractAddress) {
        let pair_class = declare('PairC1');

        let mut factory_constructor_calldata = Default::default();
        Serde::serialize(@pair_class.class_hash, ref factory_constructor_calldata);
        Serde::serialize(@DEPLOYER(), ref factory_constructor_calldata);
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
        amms_routers: Array<AMMRouter>
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
        owner: ContractAddress, network: felt252, memecoin_class_hash: ClassHash,
    ) -> ContractAddress {
        let contract = declare('UnruggableMemecoinFactory');
        let mut constructor_calldata = array![owner.into(), network, memecoin_class_hash.into(),];
        contract.deploy(@constructor_calldata).unwrap()
    }

    fn deploy_erc20(initial_supply: u256, recipient: ContractAddress) -> ContractAddress {
        let erc20_class = declare('ERC20');

        let mut token0_constructor_calldata = Default::default();
        Serde::serialize(@TOKEN0_NAME, ref token0_constructor_calldata);
        Serde::serialize(@SYMBOL, ref token0_constructor_calldata);
        Serde::serialize(@initial_supply, ref token0_constructor_calldata);
        Serde::serialize(@recipient, ref token0_constructor_calldata);

        erc20_class.deploy(@token0_constructor_calldata).unwrap()
    }
}
