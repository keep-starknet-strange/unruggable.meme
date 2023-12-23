use core::debug::PrintTrait;
use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, start_warp, stop_warp, CheatTarget
};
use starknet::{ContractAddress, contract_address_const};
use unruggable::amm::amm::AMM;
use unruggable::token_locker::{ITokenLockerDispatcher, ITokenLockerDispatcherTrait};
use unruggable::tokens::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

fn setup() -> (ContractAddress, ContractAddress, ContractAddress) {
    let owner: ContractAddress = 'owner'.try_into().unwrap();
    let locker_calldata = array![200];

    let locker_contract = declare('TokenLocker');
    let locker_address = locker_contract.deploy(@locker_calldata).unwrap();

    let initial_holder_2 = contract_address_const::<45>();
    let initial_holders: Span<ContractAddress> = array![owner, initial_holder_2].span();
    let initial_holders_amounts: Span<u256> = array![1000, 50].span();

    let mut token_calldata = array![
        owner.into(), locker_address.into(), 'TEST', 'TST', 100000.into(), 0.into()
    ];

    Serde::serialize(@initial_holders.into(), ref token_calldata);
    Serde::serialize(@initial_holders_amounts.into(), ref token_calldata);

    let token_contract = declare('UnruggableMemecoin');
    let token_address = token_contract.deploy(@token_calldata).unwrap();

    return (owner, locker_address, token_address);
}

#[test]
fn test_lock() {
    let (owner, locker, token) = setup();
    let token_dispatcher = IUnruggableMemecoinDispatcher { contract_address: token };
    let locker_dispatcher = ITokenLockerDispatcher { contract_address: locker };

    let balance = token_dispatcher.balanceOf(owner);
    balance.print();

    start_prank(CheatTarget::One(token), owner);
    token_dispatcher.approve(locker, 1000);
    stop_prank(CheatTarget::One(token));

    start_warp(CheatTarget::One(locker), 100);
    start_prank(CheatTarget::One(locker), owner);
    locker_dispatcher.lock(token, 1000);
    stop_prank(CheatTarget::One(locker));

    assert(token_dispatcher.balanceOf(owner) == 0, 'balanceOf owner not 0');

    assert(token_dispatcher.balanceOf(locker) == 1000, 'balanceOf locker not 1000');

    assert(
        locker_dispatcher.get_locked_amount(token, owner, 100) == 1000,
        'lockedAmount owner not 1000'
    );

    assert(locker_dispatcher.get_time_left(token, owner, 100) == 200, 'time left not 200');
    stop_warp(CheatTarget::One(locker));
}

#[test]
#[should_panic(expected: ('Still locked',))]
fn test_unlock_early() {
    let (owner, locker, token) = setup();
    let token_dispatcher = IUnruggableMemecoinDispatcher { contract_address: token };
    let locker_dispatcher = ITokenLockerDispatcher { contract_address: locker };

    start_prank(CheatTarget::One(token), owner);
    token_dispatcher.approve(locker, 1000);
    stop_prank(CheatTarget::One(token));

    start_warp(CheatTarget::One(locker), 100);
    start_prank(CheatTarget::One(locker), owner);
    locker_dispatcher.lock(token, 1000);
    stop_prank(CheatTarget::One(locker));

    assert(token_dispatcher.balanceOf(owner) == 0, 'balanceOf owner not 0');

    start_warp(CheatTarget::One(locker), 200);
    start_prank(CheatTarget::One(locker), owner);
    locker_dispatcher.unlock(token, 100);
    stop_prank(CheatTarget::One(locker));
    stop_warp(CheatTarget::One(locker));
}

#[test]
#[should_panic(expected: ('Lock nonexist',))]
fn test_unlock_no_owner() {
    let (owner, locker, token) = setup();
    let no_owner: ContractAddress = 'no_owner'.try_into().unwrap();
    let token_dispatcher = IUnruggableMemecoinDispatcher { contract_address: token };
    let locker_dispatcher = ITokenLockerDispatcher { contract_address: locker };

    start_prank(CheatTarget::One(token), owner);
    token_dispatcher.approve(locker, 1000);
    stop_prank(CheatTarget::One(token));

    start_warp(CheatTarget::One(locker), 100);
    start_prank(CheatTarget::One(locker), owner);
    locker_dispatcher.lock(token, 1000);
    stop_prank(CheatTarget::One(locker));

    assert(token_dispatcher.balanceOf(owner) == 0, 'balanceOf owner not 0');

    start_warp(CheatTarget::One(locker), 300);
    start_prank(CheatTarget::One(locker), no_owner);
    locker_dispatcher.unlock(token, 100);
    stop_prank(CheatTarget::One(locker));
}

#[test]
fn test_unlock() {
    let (owner, locker, token) = setup();
    let token_dispatcher = IUnruggableMemecoinDispatcher { contract_address: token };
    let locker_dispatcher = ITokenLockerDispatcher { contract_address: locker };

    start_prank(CheatTarget::One(token), owner);
    token_dispatcher.approve(locker, 1000);
    stop_prank(CheatTarget::One(token));

    start_warp(CheatTarget::One(locker), 100);
    start_prank(CheatTarget::One(locker), owner);
    locker_dispatcher.lock(token, 1000);
    stop_prank(CheatTarget::One(locker));

    assert(token_dispatcher.balanceOf(owner) == 0, 'balanceOf owner not 0');

    start_warp(CheatTarget::One(locker), 300);
    start_prank(CheatTarget::One(locker), owner);
    locker_dispatcher.unlock(token, 100);
    stop_prank(CheatTarget::One(locker));

    assert(token_dispatcher.balanceOf(locker) == 0, 'balanceOf locker not 0');

    assert(token_dispatcher.balanceOf(owner) == 1000, 'balanceOf owner not 1000');

    assert(locker_dispatcher.get_locked_amount(token, owner, 100) == 0, 'lockedAmount owner not 0');

    assert(locker_dispatcher.get_time_left(token, owner, 100) == 0, 'time left not 0');
    stop_warp(CheatTarget::One(locker));
}

#[test]
fn test_view_methods() {
    let (owner, locker, token) = setup();
    let token_dispatcher = IUnruggableMemecoinDispatcher { contract_address: token };
    let locker_dispatcher = ITokenLockerDispatcher { contract_address: locker };

    start_prank(CheatTarget::One(token), owner);
    token_dispatcher.approve(locker, 1000);
    stop_prank(CheatTarget::One(token));

    start_warp(CheatTarget::One(locker), 100);
    start_prank(CheatTarget::One(locker), owner);
    locker_dispatcher.lock(token, 1000);
    stop_prank(CheatTarget::One(locker));
    stop_warp(CheatTarget::One(locker));
}
