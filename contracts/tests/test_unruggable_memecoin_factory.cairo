use snforge_std::{declare, ContractClassTrait};
use starknet::{ContractAddress, contract_address_const};
use unruggable::amm::amm::{AMM, AMMV2};
use unruggable::tests_utils::deployer_helper::DeployerHelper::{
    deploy_memecoin_factory, deploy_contracts
};
use unruggable::tokens::factory::{
    IUnruggableMemecoinFactory, IUnruggableMemecoinFactoryDispatcher,
    IUnruggableMemecoinFactoryDispatcherTrait
};
use unruggable::tokens::interface::{
    IUnruggableMemecoin, IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

fn instantiate_params() -> (
    ContractAddress,
    felt252,
    felt252,
    u256,
    ContractAddress,
    ContractAddress,
    Span<ContractAddress>,
    Span<u256>,
) {
    let owner = contract_address_const::<42>();
    let name = 'UnruggableMemecoin';
    let symbol = 'UM';
    let initial_supply = 1000;
    let initial_holder_1 = contract_address_const::<44>();
    let initial_holder_2 = contract_address_const::<45>();
    let initial_holders = array![initial_holder_1, initial_holder_2].span();
    let initial_holders_amounts = array![50, 50].span();
    (
        owner,
        name,
        symbol,
        initial_supply,
        initial_holder_1,
        initial_holder_2,
        initial_holders,
        initial_holders_amounts
    )
}

#[test]
fn test_deploy_factory_register_amms() {
    let (_, router_address) = deploy_contracts();

    // Declare UnruggableMemecoin and use ClassHash for the Factory
    let declare_memecoin = declare('UnruggableMemecoin');

    // Declare availables AMMs for this factory
    let owner = contract_address_const::<42>();
    let jediswap_name: felt252 = AMMV2::JediSwap.into();
    let mut amms = array![AMM { name: jediswap_name, router_address }];

    let memecoin_factory_address = deploy_memecoin_factory(
        owner, declare_memecoin.class_hash, amms
    );

    let memecoin_factory = IUnruggableMemecoinFactoryDispatcher {
        contract_address: memecoin_factory_address
    };

    let amms: Span<AMM> = memecoin_factory.registered_amms();
    assert(amms.len() == 1, 'wrong amm len');
    assert((*amms.at(0)).name == jediswap_name, 'wrong amm name');
    assert((*amms.at(0)).router_address == router_address, 'wrong amm router_address');
}

#[test]
fn test_deploy_memecoin() {
    let (_, router_address) = deploy_contracts();

    // Declare UnruggableMemecoin and use ClassHash for the Factory
    let declare_memecoin = declare('UnruggableMemecoin');

    // Declare availables AMMs for this factory
    let owner = contract_address_const::<42>();
    let jediswap_name: felt252 = AMMV2::JediSwap.into();
    let mut amms = array![AMM { name: jediswap_name, router_address }];

    let memecoin_factory_address = deploy_memecoin_factory(
        owner, declare_memecoin.class_hash, amms
    );

    let memecoin_factory = IUnruggableMemecoinFactoryDispatcher {
        contract_address: memecoin_factory_address
    };

    let (
        _,
        name,
        symbol,
        initial_supply,
        initial_holder_1,
        initial_holder_2,
        initial_holders,
        initial_holders_amounts
    ) =
        instantiate_params();

    let locker_calldata = array![200];
    let locker_contract = declare('TokenLocker');
    let locker_address = locker_contract.deploy(@locker_calldata).unwrap();

    let memecoin_address = memecoin_factory
        .create_memecoin(
            owner,
            locker_address,
            name,
            symbol,
            initial_supply,
            initial_holders,
            initial_holders_amounts
        );
    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

    assert(memecoin.name() == name, 'wrong memecoin name');
    assert(memecoin.symbol() == symbol, 'wrong memecoin symbol');
    // initial supply - initial holder balance
    assert(memecoin.balance_of(memecoin_address) == initial_supply - 100, 'wrong initial supply');
    assert(memecoin.balance_of(initial_holder_1) == 50, 'wrong initial_holder_1 balance');
    assert(memecoin.balance_of(initial_holder_2) == 50, 'wrong initial_holder_2 balance');
}
