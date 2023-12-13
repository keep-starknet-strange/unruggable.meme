use core::traits::Into;
use starknet::{ContractAddress, contract_address_const};
use openzeppelin::token::erc20::interface::IERC20;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
use unruggablememecoin::unruggable_memecoin::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait,
    UnruggableMemecoin::MAX_HOLDERS_BEFORE_LAUNCH,
    UnruggableMemecoin::MAX_SUPPLY_PERCENTAGE_TEAM_ALLOCATION,
// UnruggableMemecoin::get_max_team_allocation,
};

fn deploy_contract(
    owner: ContractAddress,
    recipient: ContractAddress,
    name: felt252,
    symbol: felt252,
    initial_supply: u256,
) -> ContractAddress {
    let contract = declare('UnruggableMemecoin');
    let mut constructor_calldata = array![
        owner.into(),
        recipient.into(),
        name,
        symbol,
        initial_supply.low.into(),
        initial_supply.high.into()
    ];
    contract.deploy(@constructor_calldata).unwrap()
}

#[test]
fn test_mint() {
    let owner = contract_address_const::<42>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
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
fn test_team_alloc() {
    let owner = contract_address_const::<1>();
    let recipient = contract_address_const::<2>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, recipient, 'UnruggableMemecoin', 'URM', initial_supply
    );
    // set owner as caller
    start_prank(CheatTarget::One(contract_address), owner);

    // make transfer 
    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };
    let max_alloc: u256 = safe_dispatcher.get_max_team_allocation();

    assert(max_alloc == 100, 'Invalid max allocation');
}
#[test]
#[should_panic(expected: ('Team allocation cap reached',))]
fn test_fail_transfer_team_alloc_reached() {
    let owner = contract_address_const::<1>();
    let recipient = contract_address_const::<2>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, recipient, 'UnruggableMemecoin', 'URM', initial_supply
    );

    // make transfer 
    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };
    // Check initial balance. Should be equal to initial supply.
    let mut balance = safe_dispatcher.balance_of(owner);
    assert(balance == 0, 'Invalid owner balance');
    balance = safe_dispatcher.balance_of(recipient);
    assert(balance == initial_supply, 'Invalid recipient balance');

    // set recipient as caller
    start_prank(CheatTarget::One(contract_address), recipient);
    safe_dispatcher.transfer(owner, initial_supply);
}

#[test]
fn test_transfer_team_alloc_not_reached() {
    let owner = contract_address_const::<1>();
    let recipient = contract_address_const::<2>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, recipient, 'UnruggableMemecoin', 'URM', initial_supply
    );

    // make transfer 
    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };
    // Check initial balance. Should be equal to initial supply.
    let mut balance = safe_dispatcher.balance_of(owner);
    assert(balance == 0, 'Invalid owner balance');
    balance = safe_dispatcher.balance_of(recipient);
    assert(balance == initial_supply, 'Invalid recipient balance');

    // set recipient as caller
    start_prank(CheatTarget::One(contract_address), recipient);
    safe_dispatcher.transfer(owner, 100);
}

#[test]
#[should_panic(expected: ('Team allocation cap reached',))]
fn test_fail_transfer_from_team_alloc_reached() {
    let owner = contract_address_const::<1>();
    let recipient = contract_address_const::<2>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, recipient, 'UnruggableMemecoin', 'URM', initial_supply
    );

    // make transfer 
    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };
    // Check initial balance. Should be equal to initial supply.
    let mut balance = safe_dispatcher.balance_of(owner);
    assert(balance == 0, 'Invalid owner balance');
    balance = safe_dispatcher.balance_of(recipient);
    assert(balance == initial_supply, 'Invalid recipient balance');

    // set recipient as caller
    start_prank(CheatTarget::One(contract_address), recipient);
    safe_dispatcher.approve(owner, initial_supply);
    // set owner as caller to transfer from recipient
    start_prank(CheatTarget::One(contract_address), owner);
    safe_dispatcher.transfer_from(recipient, owner, initial_supply);
}

#[test]
fn test_transfer_from_team_alloc_not_reached() {
    let owner = contract_address_const::<1>();
    let recipient = contract_address_const::<2>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, recipient, 'UnruggableMemecoin', 'URM', initial_supply
    );

    // make transfer 
    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };
    // Check initial balance. Should be equal to initial supply.
    let mut balance = safe_dispatcher.balance_of(owner);
    assert(balance == 0, 'Invalid owner balance');
    balance = safe_dispatcher.balance_of(recipient);
    assert(balance == initial_supply, 'Invalid recipient balance');

    // set recipient as caller
    start_prank(CheatTarget::One(contract_address), recipient);
    safe_dispatcher.approve(owner, 100);
    // set owner as caller to transfer from recipient
    start_prank(CheatTarget::One(contract_address), owner);
    safe_dispatcher.transfer_from(recipient, owner, 100);
}
