use core::debug::PrintTrait;
use core::traits::Into;
use starknet::{ContractAddress, contract_address_const};
use openzeppelin::token::erc20::interface::IERC20;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use unruggablememecoin::unruggable_memecoin::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
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
