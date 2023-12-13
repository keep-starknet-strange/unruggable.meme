use core::debug::PrintTrait;
use starknet::{ContractAddress, contract_address_const};
use openzeppelin::token::erc20::interface::{ IERC20, IERC20Dispatcher, IERC20DispatcherTrait };
use snforge_std::{ ContractClass, ContractClassTrait, CheatTarget, declare, start_prank, stop_prank };

use unruggablememecoin::jediswap_interface::{
    IFactoryC1, IFactoryC1Dispatcher,
    IFactoryC1DispatcherTrait, IRouterC1, IRouterC1Dispatcher, IRouterC1DispatcherTrait
};
use unruggablememecoin::test_utils::constants::{
    TOKEN_MULTIPLIER, OWNER
};
use unruggablememecoin::test_utils::deployer_helper::DeployerHelper::{
    deploy_contracts, deploy_erc20, deploy_unruggable_memecoin_contract
};
use unruggablememecoin::unruggable_memecoin::{
    IUnruggableMemecoin, IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

#[test]
fn test_mint() {
    let owner = contract_address_const::<42>();
    let initial_supply = 1000.into();
    // TODO: validate router 
    let (_, router_address) = deploy_contracts();

    let contract_address = deploy_unruggable_memecoin_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply, router_address 
    );

    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };

    // Check total supply. Should be equal to initial supply.
    let total_supply = safe_dispatcher.total_supply();
    assert(total_supply == initial_supply, 'Invalid total supply');

    // Check initial balance. Should be equal to initial supply.
    let balance = safe_dispatcher.balance_of(owner);
    assert(balance == initial_supply, 'Invalid balance');
}

#[test]
fn test_launch_memecoin() {
    // Setup
    let (_, router_address) = deploy_contracts();
    let router_dispatcher = IRouterC1Dispatcher { contract_address: router_address };

    let initial_supply: u256 = 100 * TOKEN_MULTIPLIER;
    let counterparty_token_address = deploy_erc20(initial_supply, OWNER());
    let unruggable_meme_coin_address = deploy_unruggable_memecoin_contract(OWNER(), OWNER(), 'UnruggableMemecoin', 'MT',initial_supply, router_address);

    let token_dispatcher = IERC20Dispatcher { contract_address: counterparty_token_address };
    let unruggable_meme_coin_dispatcher = IUnruggableMemecoinDispatcher { contract_address: unruggable_meme_coin_address };
    
    // Transfer 10 counterparty_token to UnruggableMemecoin contract
    start_prank(CheatTarget::One(counterparty_token_address), OWNER());
    token_dispatcher.transfer(unruggable_meme_coin_address, 10 * TOKEN_MULTIPLIER);
    stop_prank(CheatTarget::One(counterparty_token_address));

    // Transfer 10 MT to UnruggableMemecoin contract
    start_prank(CheatTarget::One(unruggable_meme_coin_address), OWNER());
    unruggable_meme_coin_dispatcher.transfer(unruggable_meme_coin_address, 10 * TOKEN_MULTIPLIER);
    stop_prank(CheatTarget::One(unruggable_meme_coin_address));

    // unruggable_meme_coin approves to router
    start_prank(CheatTarget::One(unruggable_meme_coin_address), unruggable_meme_coin_address);
    unruggable_meme_coin_dispatcher.approve(router_address, 10 * TOKEN_MULTIPLIER);
    stop_prank(CheatTarget::One(unruggable_meme_coin_address));

    start_prank(CheatTarget::One(counterparty_token_address), unruggable_meme_coin_address);
    token_dispatcher.approve(router_address, 10 * TOKEN_MULTIPLIER);
    stop_prank(CheatTarget::One(counterparty_token_address));

    // start_prank(CheatTarget::One(unruggable_meme_coin_address), OWNER());
    unruggable_meme_coin_dispatcher.launch_memecoin(counterparty_token_address, 10 * TOKEN_MULTIPLIER, 10 * TOKEN_MULTIPLIER);
    // stop_prank(CheatTarget::One(unruggable_meme_coin_address));
}