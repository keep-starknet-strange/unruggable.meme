use core::debug::PrintTrait;
use core::traits::Into;
use starknet::{ContractAddress, contract_address_const};
use openzeppelin::token::erc20::interface::IERC20;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
use unruggablememecoin::unruggable_memecoin::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait,
    UnruggableMemecoin::MAX_HOLDERS_BEFORE_LAUNCH
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
fn test_transfer() {
    let owner = contract_address_const::<42>();
    let recipient = contract_address_const::<43>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
    );


    // set owner as caller
    start_prank(CheatTarget::One(contract_address), owner);

    // make transfer 
    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };
    safe_dispatcher.transfer(recipient, initial_supply - 1);

    // check owner's balance. Should be equal to initial supply.
    let owner_balance = safe_dispatcher.balance_of(owner);
    assert(owner_balance == 1, 'invalid owner balance');

    // check initial balance. Should be equal to initial supply.
    let recipient_balance = safe_dispatcher.balance_of(recipient);
    assert(recipient_balance == initial_supply - 1 , 'invalid recipient balance');
}


#[test]
fn test_transfer_2() {
    /// Ensure that transfers can be made out to 
    /// up to `MAX_HOLDERS_BEFORE_LAUNCH` addresses

    let owner = contract_address_const::<42>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
    );


    // set owner as caller
    start_prank(CheatTarget::One(contract_address), owner);

    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };


    // index starts from 1 because the owner
    // is considered to be the first hodler
    let mut index = 1; 
    loop {
        if index == MAX_HOLDERS_BEFORE_LAUNCH {
            break;
        }

        // make transfer 
        let recipient: ContractAddress = (index.into() + 9999999).try_into().unwrap();
        safe_dispatcher.transfer(recipient, 1);

        // check initial balance. Should be equal to initial supply.
        let recipient_balance = safe_dispatcher.balance_of(recipient);
        assert(recipient_balance == 1, 'invalid recipient balance');

        index += 1;
    };
}


#[test]
#[should_panic(expected: ('Unruggable: max holders reached', ))]
fn test_transfer_3() {
    /// Ensure that transfers can only be made out to 
    /// up to `MAX_HOLDERS_BEFORE_LAUNCH` addresses

    let owner = contract_address_const::<42>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
    );

    // set owner as caller
    start_prank(CheatTarget::One(contract_address), owner);

    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };

    let mut index = 0; 
    loop {
        if index == MAX_HOLDERS_BEFORE_LAUNCH + 1 {
            break;
        }

        // make transfer 
        let recipient: ContractAddress = (index.into() + 9999999).try_into().unwrap();
        safe_dispatcher.transfer(recipient, 1);

        // check initial balance. Should be equal to initial supply.
        let recipient_balance = safe_dispatcher.balance_of(recipient);
        assert(recipient_balance == 1, 'invalid recipient balance');

        index += 1;
    };
}



#[test]
fn test_transfer_4() {
    /// Ensure that transfer to more than `MAX_HOLDERS_BEFORE_LAUNCH`
    /// works after the token is launched

    let owner = contract_address_const::<42>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
    );


    // set owner as caller
    start_prank(CheatTarget::One(contract_address), owner);

    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };
    // launch memecoin
    safe_dispatcher.launch_memecoin();

    let mut index = 0; 
    loop {
        if index == MAX_HOLDERS_BEFORE_LAUNCH + 1 {
            break;
        }

        // make transfer 
        let recipient: ContractAddress = (index.into() + 9999999).try_into().unwrap();
        safe_dispatcher.transfer(recipient, 1);

        // check initial balance. Should be equal to initial supply.
        let recipient_balance = safe_dispatcher.balance_of(recipient);
        assert(recipient_balance == 1, 'invalid recipient balance');

        index += 1;
    };
}



#[test]
fn test_transfer_from() {
    let owner = contract_address_const::<42>();
    let recipient = contract_address_const::<43>();
    let approved = contract_address_const::<44>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
    );

    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };

    // set owner as caller
    start_prank(CheatTarget::One(contract_address), owner);

    // approve to spend initial_supply
    safe_dispatcher.approve(approved, initial_supply);

    // set approved as caller
    start_prank(CheatTarget::One(contract_address), approved);

    // make transfer 
    safe_dispatcher.transfer_from(owner, recipient, initial_supply - 1);

    // check owner's balance. Should be equal to initial supply.
    let owner_balance = safe_dispatcher.balance_of(owner);
    assert(owner_balance == 1, 'invalid owner balance');

    // check that approval was spent
    let approved_allowance = safe_dispatcher.allowance(owner, approved);
    assert(approved_allowance == 1, 'invalid approved balance');

    // check initial balance. Should be equal to initial supply.
    let recipient_balance = safe_dispatcher.balance_of(recipient);
    assert(recipient_balance == initial_supply - 1 , 'invalid recipient balance');
}


#[test]
fn test_transfer_from_2() {
    /// Ensure that transfers can be made out to 
    /// up to `MAX_HOLDERS_BEFORE_LAUNCH` addresses

    let owner = contract_address_const::<42>();
    let approved = contract_address_const::<44>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
    );

    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };


    // set owner as caller
    start_prank(CheatTarget::One(contract_address), owner);

    // approve to spend initial_supply
    safe_dispatcher.approve(approved, initial_supply);

    // set approved as caller
    start_prank(CheatTarget::One(contract_address), approved);

    let mut index = 0; 
    loop {
        if index == MAX_HOLDERS_BEFORE_LAUNCH {
            break;
        }

        // make transfer 
        let recipient: ContractAddress = (index.into() + 9999999).try_into().unwrap();
        safe_dispatcher.transfer_from(owner, recipient, 1);

        // check initial balance. Should be equal to initial supply.
        let recipient_balance = safe_dispatcher.balance_of(recipient);
        assert(recipient_balance == 1, 'invalid recipient balance');

        index += 1;
    };
}


#[test]
#[should_panic(expected: ('Unruggable: max holders reached', ))]
fn test_transfer_from_3() {
    /// Ensure that transfers can only be made out to 
    /// up to `MAX_HOLDERS_BEFORE_LAUNCH` addresses

    let owner = contract_address_const::<42>();
    let approved = contract_address_const::<44>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
    );


    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };

    // set owner as caller
    start_prank(CheatTarget::One(contract_address), owner);

    // approve to spend initial_supply
    safe_dispatcher.approve(approved, initial_supply);

    // set approved as caller
    start_prank(CheatTarget::One(contract_address), approved);

    let mut index = 0; 
    loop {
        if index == MAX_HOLDERS_BEFORE_LAUNCH + 1 {
            break;
        }

        // make transfer 
        let recipient: ContractAddress = (index.into() + 9999999).try_into().unwrap();
        safe_dispatcher.transfer_from(owner, recipient, 1);

        // check initial balance. Should be equal to initial supply.
        let recipient_balance = safe_dispatcher.balance_of(recipient);
        assert(recipient_balance == 1, 'invalid recipient balance');

        index += 1;
    };
}



#[test]
fn test_transfer_from_4() {
    /// Ensure that transfer to more than `MAX_HOLDERS_BEFORE_LAUNCH`
    /// works after the token is launched

    let owner = contract_address_const::<42>();
    let approved = contract_address_const::<44>();
    let initial_supply = 1000.into();
    let contract_address = deploy_contract(
        owner, owner, 'UnruggableMemecoin', 'MT', initial_supply
    );

    let safe_dispatcher = IUnruggableMemecoinDispatcher { contract_address };


    // set owner as caller
    start_prank(CheatTarget::One(contract_address), owner);

    // approve to spend initial_supply
    safe_dispatcher.approve(approved, initial_supply);

    // launch memecoin
    safe_dispatcher.launch_memecoin();

    // set approved as caller
    start_prank(CheatTarget::One(contract_address), approved);


    let mut index = 0; 
    loop {
        if index == MAX_HOLDERS_BEFORE_LAUNCH + 1 {
            break;
        }

        // make transfer 
        let recipient: ContractAddress = (index.into() + 9999999).try_into().unwrap();
        safe_dispatcher.transfer_from(owner, recipient, 1);


        // check initial balance. Should be equal to initial supply.
        let recipient_balance = safe_dispatcher.balance_of(recipient);
        assert(recipient_balance == 1, 'invalid recipient balance');

        index += 1;
    };
}





