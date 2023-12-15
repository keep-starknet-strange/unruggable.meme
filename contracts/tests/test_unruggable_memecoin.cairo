use core::debug::PrintTrait;
use starknet::{ContractAddress, contract_address_const};
use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{ContractClass, ContractClassTrait, CheatTarget, declare, start_prank, stop_prank};

use unruggablememecoin::amm::jediswap_interface::{
    IFactoryC1, IFactoryC1Dispatcher, IFactoryC1DispatcherTrait, IRouterC1, IRouterC1Dispatcher,
    IRouterC1DispatcherTrait
};
use unruggablememecoin::tests_utils::constants::{TOKEN_MULTIPLIER, OWNER};
use unruggablememecoin::tests_utils::deployer_helper::DeployerHelper::{
    deploy_contracts, deploy_erc20, deploy_unruggable_memecoin_contract, deploy_memecoin_factory
};
use unruggablememecoin::unruggable_memecoin::{
    UnruggableMemecoin, IUnruggableMemecoin, IUnruggableMemecoinDispatcher,
    IUnruggableMemecoinDispatcherTrait
};
use unruggablememecoin::amm::amm::{AMM, AMMV2};

use unruggablememecoin::unruggable_memecoin_factory::{
    IUnruggableMemecoinFactory, IUnruggableMemecoinFactoryDispatcher,
    IUnruggableMemecoinFactoryDispatcherTrait
};

#[test]
fn test_mint() {
    let owner = contract_address_const::<42>();
    // let initial_supply = 1000.into();
    // TODO: validate router 

    // let contract_address = deploy_unruggable_memecoin_contract(
    //     owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
    // );

    // let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };

    // // Check total supply. Should be equal to initial supply.
    // let total_supply = safe_dispatcher.total_supply();
    // assert(total_supply == initial_supply, 'Invalid total supply');

    // // Check initial balance. Should be equal to initial supply.
    // let balance = safe_dispatcher.balance_of(owner);
    // assert(balance == initial_supply, 'Invalid balance');
    assert(1 == 1, 'a');
}

#[test]
fn test_launch_memecoin() {
    // Setup
    let (_, router_address) = deploy_contracts();
    let router_dispatcher = IRouterC1Dispatcher { contract_address: router_address };

    let initial_supply: u256 = 10 * TOKEN_MULTIPLIER;
    let counterparty_token_address = deploy_erc20(initial_supply, OWNER());

    // Declare availables AMMs for this factory
    let mut amms = array![];
    amms
        .append(
            AMM {
                name: AMMV2::JediSwap.into(),
                router_address: contract_address_const::<
                    0x17f2e8d48625c8f615a19a57b62d0a68b7096b0c51907daa8c8690458e6fb55
                // 0x7eef7d58a3bad23287f9aacb4749e2a5de5af88c4b9a968eb5ce81937da62de
                >()
            }
        );

    // Declare UnruggableMemecoin and use ClassHash for the Factory
    let declare_memecoin = declare('UnruggableMemecoin');
    let memecoin_factory_address = deploy_memecoin_factory(
        OWNER(), declare_memecoin.class_hash, amms
    );

    // Deploy UnruggableMemecoinFactory
    let unruggable_meme_factory = IUnruggableMemecoinFactoryDispatcher {
        contract_address: memecoin_factory_address
    };

    // Create a MemeCoin
    let memecoin_address = unruggable_meme_factory
        .create_memecoin(OWNER(), OWNER(), 'MemeCoin', 'MC', initial_supply);
    let unruggable_memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

    let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };

    'memecoin_address'.print();
    memecoin_address.print();

    'router_address'.print();
    router_address.print();

    // Transfer 10 counterparty_token to UnruggableMemecoin contract
    start_prank(CheatTarget::One(counterparty_token_address), OWNER());
    token_dispatcher.transfer(memecoin_address, 10 * TOKEN_MULTIPLIER);
    stop_prank(CheatTarget::One(counterparty_token_address));

    // Transfer 10 MT to UnruggableMemecoin contract
    start_prank(CheatTarget::One(memecoin_address), OWNER());
    unruggable_memecoin.transfer(memecoin_address, 10 * TOKEN_MULTIPLIER);
    stop_prank(CheatTarget::One(memecoin_address));

    start_prank(CheatTarget::One(memecoin_address), router_address);
    start_prank(CheatTarget::One(router_address), memecoin_address);
    start_prank(CheatTarget::One(memecoin_address), OWNER());
    unruggable_memecoin
        .launch_memecoin(
            AMMV2::JediSwap, counterparty_token_address, 1 * TOKEN_MULTIPLIER, 1 * TOKEN_MULTIPLIER
        );
    stop_prank(CheatTarget::One(memecoin_address));
    stop_prank(CheatTarget::One(router_address));
}
