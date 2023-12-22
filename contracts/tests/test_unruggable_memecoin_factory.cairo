use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
use starknet::{ContractAddress, contract_address_const};
use traits::{Into, TryInto};
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
use unruggable::tokens::erc20::{ERC20Token};

use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};

const ETH_UNIT_DECIMALS: u256 = 1000000000000000000;

fn instantiate_params() -> (
    ContractAddress,
    felt252,
    felt252,
    u256,
    ContractAddress,
    ContractAddress,
    Span<ContractAddress>,
    Span<u256>,
    IERC20Dispatcher,
    felt252
) {
    let owner = contract_address_const::<42>();
    let name = 'UnruggableMemecoin';
    let symbol = 'UM';
    let initial_supply = 1000;
    let initial_holder_1 = contract_address_const::<44>();
    let initial_holder_2 = contract_address_const::<45>();
    let initial_holders = array![initial_holder_1, initial_holder_2].span();
    let initial_holders_amounts = array![50, 50].span();
    let erc20_token = declare('ERC20Token');
    let eth_amount: u256 = 2 * ETH_UNIT_DECIMALS;
    let erc20_calldata: Array<felt252> = array![
        eth_amount.low.into(), eth_amount.high.into(), owner.into()
    ];
    let eth = erc20_token.deploy(@erc20_calldata).unwrap();
    let contract_address_salt = 'salty';
    (
        owner,
        name,
        symbol,
        initial_supply,
        initial_holder_1,
        initial_holder_2,
        initial_holders,
        initial_holders_amounts,
        IERC20Dispatcher { contract_address: eth },
        contract_address_salt
    )
}

#[test]
fn test_deploy_factory_amm_router_address() {
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

    let amm_router_address = memecoin_factory.amm_router_address(amm_name: jediswap_name);
    assert(amm_router_address == router_address, 'wrong amm router_address');
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
        initial_holders_amounts,
        eth,
        contract_address_salt
    ) =
        instantiate_params();

    let locker_calldata = array![200];
    let locker_contract = declare('TokenLocker');
    let locker_address = locker_contract.deploy(@locker_calldata).unwrap();

    let eth_amount: u256 = 1 * ETH_UNIT_DECIMALS;
    assert(eth.balance_of(owner) == eth_amount * 2, 'wrong eth balance');
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(spender: memecoin_factory.contract_address, amount: eth_amount);
    assert(
        eth.allowance(:owner, spender: memecoin_factory.contract_address) == eth_amount,
        'wrong eth allowance'
    );
    start_prank(CheatTarget::One(memecoin_factory.contract_address), owner);
    let memecoin_address = memecoin_factory
        .create_memecoin(
            :owner,
            :locker_address,
            :name,
            :symbol,
            :initial_supply,
            :initial_holders,
            :initial_holders_amounts,
            eth_contract: eth,
            :contract_address_salt
        );
    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

    assert(memecoin.name() == name, 'wrong memecoin name');
    assert(memecoin.symbol() == symbol, 'wrong memecoin symbol');
    // initial supply - initial holder balance
    assert(memecoin.balance_of(memecoin_address) == initial_supply - 100, 'wrong initial supply');
    assert(memecoin.balance_of(initial_holder_1) == 50, 'wrong initial_holder_1 balance');
    assert(memecoin.balance_of(initial_holder_2) == 50, 'wrong initial_holder_2 balance');
}


#[test]
fn test_is_memecoin() {
    let (_, router_address) = deploy_contracts();

    // Declare UnruggableMemecoin and use ClassHash for the Factory
    let declare_memecoin = declare('UnruggableMemecoin');

    // Declare availables AMMs for this factory
    let owner = contract_address_const::<42>();
    let mut amms = array![];

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
        initial_holders_amounts,
        eth,
        contract_address_salt
    ) =
        instantiate_params();

    let locker_calldata = array![200];
    let locker_contract = declare('TokenLocker');
    let locker_address = locker_contract.deploy(@locker_calldata).unwrap();

    let memecoin_address = memecoin_factory
        .create_memecoin(
            :owner,
            :locker_address,
            :name,
            :symbol,
            :initial_supply,
            :initial_holders,
            :initial_holders_amounts,
            eth_contract: eth,
            :contract_address_salt
        );

    assert(memecoin_factory.is_memecoin(address: memecoin_address), 'wrong memecoin status');
    assert(
        !memecoin_factory.is_memecoin(address: (memecoin_address.into() + 1).try_into().unwrap()),
        'wrong memecoin status'
    );
}
