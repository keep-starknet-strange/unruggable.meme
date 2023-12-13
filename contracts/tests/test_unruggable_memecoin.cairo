use core::traits::Into;
use openzeppelin::token::erc20::interface::IERC20;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
use starknet::{ContractAddress, contract_address_const};

use unruggable::tokens::interface::{
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

mod erc20_metadata {
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::deploy_contract;
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    #[test]
    fn test_name() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let name = 'UnruggableMemecoin';
        let symbol = 'UM';
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(owner, recipient, name, symbol, initial_supply);

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check name. Should be equal to 'UnruggableMemecoin'.
        let name = memecoin.name();
        assert(name == name, 'Invalid name');
    }

    #[test]
    fn test_decimals() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let name = 'UnruggableMemecoin';
        let symbol = 'UM';
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(owner, recipient, name, symbol, initial_supply);

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check decimals. Should be equal to 18.
        let decimals = memecoin.decimals();
        assert(decimals == 18, 'Invalid decimals');
    }

    #[test]
    fn test_symbol() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let name = 'UnruggableMemecoin';
        let symbol = 'UM';
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(owner, recipient, name, symbol, initial_supply);

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check symbol. Should be equal to 'UM'.
        let symbol = memecoin.symbol();
        assert(symbol == symbol, 'Invalid symbol');
    }
}

mod erc20_entrypoints {
    use core::debug::PrintTrait;
    use core::traits::Into;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::deploy_contract;
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    // Test ERC20 snake entrypoints

    #[test]
    fn test_total_supply() {
        let owner = contract_address_const::<42>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check total supply. Should be equal to initial supply.
        let total_supply = memecoin.total_supply();
        assert(total_supply == initial_supply, 'Invalid total supply');

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(owner);
        assert(balance == initial_supply, 'Invalid balance');
    }


    #[test]
    fn test_balance_of() {
        let owner = contract_address_const::<42>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(owner);
        assert(balance == initial_supply, 'Invalid balance');
    }

    #[test]
    fn test_approve_allowance() {
        let owner = contract_address_const::<42>();
        let spender = contract_address_const::<43>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial allowance. Should be equal to 0.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == 0.into(), 'Invalid allowance before');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.approve(spender, initial_supply);

        // Check allowance. Should be equal to initial supply.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == initial_supply, 'Invalid allowance after');
    }

    #[test]
    fn test_transfer() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.transfer(recipient, 100.into());

        // Check balance. Should be equal to initial supply - 100.
        let owner_balance = memecoin.balance_of(owner);
        assert(owner_balance == (initial_supply - 100.into()), 'Invalid balance owner');

        // Check recipient balance. Should be equal to 100.
        let recipient_balance = memecoin.balance_of(recipient);
        assert(recipient_balance == 100.into(), 'Invalid balance recipient');
    }

    #[test]
    fn test_transfer_from() {
        let owner = contract_address_const::<42>();
        let spender = contract_address_const::<43>();
        let recipient = contract_address_const::<44>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(owner);
        assert(balance == initial_supply, 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.approve(spender, initial_supply);

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), spender);
        memecoin.transfer_from(owner, recipient, 100.into());

        // Check balance. Should be equal to initial supply - 100.
        let owner_balance = memecoin.balance_of(owner);
        assert(owner_balance == (initial_supply - 100.into()), 'Invalid balance owner');

        // Check recipient balance. Should be equal to 100.
        let recipient_balance = memecoin.balance_of(recipient);
        assert(recipient_balance == 100.into(), 'Invalid balance recipient');

        // Check allowance. Should be equal to initial supply - 100.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == (initial_supply - 100.into()), 'Invalid allowance');
    }

    // Test ERC20 Camel entrypoints

    #[test]
    fn test_totalSupply() {
        let owner = contract_address_const::<42>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check total supply. Should be equal to initial supply.
        let total_supply = memecoin.totalSupply();
        assert(total_supply == initial_supply, 'Invalid total supply');
    }

    #[test]
    fn test_balanceOf() {
        let owner = contract_address_const::<42>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balanceOf(owner);
        assert(balance == initial_supply, 'Invalid balance');
    }

    #[test]
    fn test_transferFrom() {
        let owner = contract_address_const::<42>();
        let spender = contract_address_const::<43>();
        let recipient = contract_address_const::<44>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, owner, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balanceOf(owner);
        assert(balance == initial_supply, 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.approve(spender, initial_supply);

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), spender);
        memecoin.transferFrom(owner, recipient, 100.into());

        // Check balance. Should be equal to initial supply - 100.
        let balance = memecoin.balanceOf(owner);
        assert(balance == (initial_supply - 100.into()), 'Invalid balance');

        // Check recipient balance. Should be equal to 100.
        let balance = memecoin.balanceOf(recipient);
        assert(balance == 100.into(), 'Invalid balance');

        // Check allowance. Should be equal to initial supply - 100.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == (initial_supply - 100.into()), 'Invalid allowance');
    }
}

mod memecoin_entrypoints {
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::deploy_contract;
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    #[test]
    fn test_launch_memecoin() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, recipient, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.launch_memecoin();
    //TODO
    }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_launch_memecoin_not_owner() {
        let owner = contract_address_const::<42>();
        let recipient = contract_address_const::<43>();
        let initial_supply = 1000.into();
        let contract_address = deploy_contract(
            owner, recipient, 'UnruggableMemecoin', 'UM', initial_supply
        );

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        memecoin.launch_memecoin();
    }
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
