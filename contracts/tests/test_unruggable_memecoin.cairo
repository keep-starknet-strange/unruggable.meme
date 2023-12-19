use core::array::ArrayTrait;
use core::debug::PrintTrait;
use core::serde::Serde;
use core::traits::Into;
use openzeppelin::token::erc20::interface::IERC20;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction};
use starknet::{ContractAddress, contract_address_const,};

use unruggable::tokens::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

fn deploy_contract(
    owner: ContractAddress,
    name: felt252,
    symbol: felt252,
    initial_supply: u256,
    initial_holders: Span<ContractAddress>,
    initial_holders_amounts: Span<u256>,
) -> Result<ContractAddress, RevertedTransaction> {
    let contract = declare('UnruggableMemecoin');
    let mut constructor_calldata = array![
        owner.into(), name, symbol, initial_supply.low.into(), initial_supply.high.into()
    ];
    Serde::serialize(@initial_holders.into(), ref constructor_calldata);
    Serde::serialize(@initial_holders_amounts.into(), ref constructor_calldata);
    contract.deploy(@constructor_calldata)
}

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
    let initial_supply: u256 = 1000;
    let initial_holder_1 = contract_address_const::<44>();
    let initial_holder_2 = contract_address_const::<45>();
    let initial_holders = array![initial_holder_1, initial_holder_2].span();
    let initial_holders_amounts: Span<u256> = array![50.into(), 50.into()].span();
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


mod erc20_metadata {
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::{deploy_contract, instantiate_params};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    #[test]
    fn test_name() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check name. Should be equal to 'UnruggableMemecoin'.
        let name = memecoin.name();
        assert(name == 'UnruggableMemecoin', 'Invalid name');
    }

    #[test]
    fn test_decimals() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check decimals. Should be equal to 18.
        let decimals = memecoin.decimals();
        assert(decimals == 18, 'Invalid decimals');
    }
    #[test]
    fn test_symbol() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };
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
    use super::{deploy_contract, instantiate_params};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    // Test ERC20 snake entrypoints

    #[test]
    fn test_total_supply() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check total supply. Should be equal to initial supply.
        let total_supply = memecoin.total_supply();
        assert(total_supply == initial_supply, 'Invalid total supply');
    }

    #[test]
    fn test_balance_of() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial recipient balance. Should be equal to 900.
        let balance = memecoin.balance_of(memecoin.contract_address);
        assert(balance == 900, 'Invalid balance');
        // Check initial holder 1 balance. Should be equal to 50.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');
        // Check initial holder 2 balance. Should be equal to 50.
        let balance = memecoin.balance_of(initial_holder_2);
        assert(balance == 50, 'Invalid balance');
    }

    #[test]
    fn test_approve_allowance() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial allowance. Should be equal to 0.
        let allowance = memecoin.allowance(initial_holder_1, initial_holder_2);
        assert(allowance == 0.into(), 'Invalid allowance before');

        let balance = memecoin.balance_of(initial_holder_2);

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        memecoin.approve(initial_holder_2, balance);

        // Check allowance. Should be equal to initial supply.
        let allowance = memecoin.allowance(initial_holder_1, initial_holder_2);
        assert(allowance == balance, 'Invalid allowance after');
    }

    #[test]
    fn test_transfer() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Transfer 100 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        memecoin.transfer(initial_holder_2, 5.into());

        // Check balance. Should be equal to 50 - 5.
        let initial_holder_1_balance = memecoin.balance_of(initial_holder_1);
        assert(initial_holder_1_balance == (50 - 5), 'Invalid balance owner');

        // Check recipient balance. Should be equal to 100.
        let recipient_balance = memecoin.balance_of(initial_holder_2);
        assert(recipient_balance == 50 + 5.into(), 'Invalid balance recipient');
    }

    #[test]
    fn test_transfer_from() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let spender = contract_address_const::<46>();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply - initial distrib of 2*50.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        memecoin.approve(initial_holder_2, balance);

        // Transfer 20 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_2);
        memecoin.transfer_from(initial_holder_1, initial_holder_2, 20);

        // Check balance. Should be equal to 50 - 20.
        let initial_holder_1_bal = memecoin.balance_of(initial_holder_1);
        assert(initial_holder_1_bal == (50 - 20), 'Invalid balance owner');

        // Check recipient balance. Should be equal to 70.
        let recipient_balance = memecoin.balance_of(initial_holder_2);
        assert(recipient_balance == 50 + 20, 'Invalid balance recipient');

        // Check allowance. Should be equal to 50 - transfered amount.
        let allowance = memecoin.allowance(initial_holder_1, initial_holder_2);
        assert(allowance == (balance - 20), 'Invalid allowance');
    }

    // Test ERC20 Camel entrypoints

    #[test]
    fn test_totalSupply() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check total supply. Should be equal to initial supply.
        let total_supply = memecoin.totalSupply();
        assert(total_supply == initial_supply, 'Invalid total supply');
    }
    #[test]
    fn test_balanceOf() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial recipient balance. Should be equal to 900.
        let balance = memecoin.balanceOf(memecoin.contract_address);
        assert(balance == 900, 'Invalid balance');
        // Check initial holder 1 balance. Should be equal to 50.
        let balance = memecoin.balanceOf(initial_holder_1);
        assert(balance == 50, 'Invalid balance');
        // Check initial holder 2 balance. Should be equal to 50.
        let balance = memecoin.balanceOf(initial_holder_1);
        assert(balance == 50, 'Invalid balance');
    }
    #[test]
    fn test_transferFrom() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let spender = contract_address_const::<46>();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply - initial distrib of 2*50.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        memecoin.approve(initial_holder_2, balance);

        // Transfer 20 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_2);
        memecoin.transfer_from(initial_holder_1, initial_holder_2, 20);

        // Check balance. Should be equal to 50 - 20.
        let initial_holder_1_bal = memecoin.balance_of(initial_holder_1);
        assert(initial_holder_1_bal == (50 - 20), 'Invalid balance owner');

        // Check recipient balance. Should be equal to 70.
        let recipient_balance = memecoin.balance_of(initial_holder_2);
        assert(recipient_balance == 50 + 20, 'Invalid balance recipient');

        // Check allowance. Should be equal to 50 - transfered amount.
        let allowance = memecoin.allowance(initial_holder_1, initial_holder_2);
        assert(allowance == (balance - 20), 'Invalid allowance');
    }
}
mod memecoin_entrypoints {
    use core::debug::PrintTrait;
    use core::traits::Into;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::{deploy_contract, instantiate_params};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    #[test]
    fn test_launch_memecoin() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.launch_memecoin();

        assert(memecoin.launched(), 'Coin not launched');
    //TODO
    }

    #[test]
    #[should_panic(expected: ('Caller is not the owner',))]
    fn test_launch_memecoin_not_owner() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        memecoin.launch_memecoin();
    }

    #[test]
    fn test_get_team_allocation() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        let team_alloc = memecoin.get_team_allocation();
        // theorical team allocation is 10%, so initial_supply * MAX_TEAM_ALLOC / 100
        // 1000 * 100 / 100 = 100
        assert(team_alloc == 100, 'Invalid team allocation');
    }

    #[test]
    #[should_panic(expected: ('Max buy cap reached',))]
    fn test_transfer_max_percentage() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let alice = contract_address_const::<53>();

        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');

        // Transfer 1 token from initial_holder_1 to alice.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        let send_amount = memecoin.transfer(alice, 50);
    }

    #[test]
    #[should_panic(expected: ('Max buy cap reached',))]
    fn test_transfer_from_max_percentage() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let alice = contract_address_const::<53>();

        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');

        // Transfer 1 token from owner to alice.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        let send_amount = memecoin.transfer_from(initial_holder_1, alice, 50);
    }

    #[test]
    fn test_classic_max_percentage() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();
        let alice = contract_address_const::<53>();

        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to initial supply.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');

        // Transfer 1 token from owner to alice.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        let send_amount = memecoin.transfer(alice, 1);
        assert(memecoin.balance_of(alice) == 1, 'Invalid balance');
    }
}
mod custom_constructor {
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::{deploy_contract, instantiate_params};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    #[test]
    #[should_panic(expected: ('Unruggable: arrays len dif',))]
    fn test_constructor_initial_holders_arrays_len_mismatch() {
        let (owner, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _) =
            instantiate_params();
        let initial_holder_3 = contract_address_const::<52>();
        let initial_holder_4 = contract_address_const::<53>();
        let initial_holders = array![
            initial_holder_1, initial_holder_2, initial_holder_3, initial_holder_4
        ]
            .span();
        let initial_holders_amounts = array![50.into(), 40.into(), 10.into()].span();
        match deploy_contract(
            owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => address.print(),
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_constructor_initial_holders_arrays_len_is_equal() {
        let (owner, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _) =
            instantiate_params();
        let initial_holder_3 = contract_address_const::<52>();
        // array_len is 4
        let initial_holders = array![initial_holder_1, initial_holder_2, initial_holder_3].span();
        // array_len is 4
        let initial_holders_amounts = array![50.into(), 40.into(), 10.into()].span();
        match deploy_contract(
            owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    #[should_panic(expected: ('Unruggable: max holders reached',))]
    fn test_max_holders_reached() {
        let (owner, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _) =
            instantiate_params();
        let initial_holder_3 = contract_address_const::<52>();
        let initial_holder_4 = contract_address_const::<53>();
        let initial_holder_5 = contract_address_const::<54>();
        let initial_holder_6 = contract_address_const::<55>();
        let initial_holder_7 = contract_address_const::<56>();
        let initial_holder_8 = contract_address_const::<57>();
        let initial_holder_9 = contract_address_const::<58>();
        let initial_holder_10 = contract_address_const::<59>();
        let initial_holder_11 = contract_address_const::<60>();

        // 11 holders
        let initial_holders = array![
            initial_holder_1,
            initial_holder_2,
            initial_holder_3,
            initial_holder_4,
            initial_holder_5,
            initial_holder_6,
            initial_holder_7,
            initial_holder_8,
            initial_holder_9,
            initial_holder_10,
            initial_holder_11
        ]
            .span();
        let initial_holders_amounts = array![
            50.into(),
            41.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
            1.into(),
        ]
            .span();

        match deploy_contract(
            owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => address.print(),
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_max_holders_not_reached() {
        let (owner, name, symbol, initial_supply, initial_holder_1, initial_holder_2, _, _) =
            instantiate_params();
        let initial_holder_3 = contract_address_const::<52>();
        let initial_holder_4 = contract_address_const::<53>();
        let initial_holder_5 = contract_address_const::<54>();
        // 5 holders
        let initial_holders = array![
            initial_holder_1,
            initial_holder_2,
            initial_holder_3,
            initial_holder_4,
            initial_holder_5,
        ]
            .span();
        let initial_holders_amounts = array![50.into(), 47.into(), 1.into(), 1.into(), 1.into(),]
            .span();

        match deploy_contract(
            owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }

    #[test]
    fn test_initial_recipient_ok() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            initial_holders_amounts
        ) =
            instantiate_params();

        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };
        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        let contract_bal = memecoin.balance_of(memecoin.contract_address);
        assert(contract_bal == 900, 'Invalid balance');
    }
    #[test]
    #[should_panic(expected: ('Unruggable: max team allocation',))]
    fn test_max_team_allocation_fail() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        // team should have less than 100 tokens
        let initial_holders_amounts = array![100.into(), 50.into(),].span();
        match deploy_contract(
            owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_max_team_allocation_ok() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        // team should have less than 100 tokens
        let initial_holders_amounts = array![50.into(), 50.into(),].span();
        match deploy_contract(
            owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
    #[test]
    fn test_max_team_allocation_ok2() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        // team should have less than 100 tokens
        let initial_holders_amounts = array![50.into(), 40.into(),].span();
        match deploy_contract(
            owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
        ) {
            Result::Ok(address) => {},
            Result::Err(msg) => panic(msg.panic_data),
        }
    }
}
mod memecoin_internals {
    use UnruggableMemecoin::{
        UnruggableMemecoinInternalImpl, SnakeEntrypoints, UnruggableEntrypoints,
        MAX_HOLDERS_BEFORE_LAUNCH
    };
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::{deploy_contract, instantiate_params};
    use unruggable::tokens::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };
    use unruggable::tokens::memecoin::UnruggableMemecoin;

    #[test]
    fn test__transfer_recipients_equal_holder_cap() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        let initial_holders_amounts = array![50.into(), 30.into(),].span();

        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        let mut index = 0;
        loop {
            // MAX_HOLDERS_BEFORE_LAUNCH - 3 because there are 3 initial holders
            if index == MAX_HOLDERS_BEFORE_LAUNCH - 2 {
                break;
            }

            // Transfer 1 token to the unique recipient
            // create a unique address
            let unique_recipient: ContractAddress = (index.into() + 9999).try_into().unwrap();
            start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
            memecoin.transfer(unique_recipient, 1.into());

            // Check recipient balance. Should be equal to 1.
            let recipient_balance = memecoin.balanceOf(unique_recipient);
            assert(recipient_balance == 1.into(), 'Invalid balance recipient');

            index += 1;
        };
    }
    #[test]
    fn test__transfer_existing_holders() {
        /// pre launch holder number should not change when
        /// transfer is done to recipient(s) who already have tokens

        /// to test this, we are going to continously self transfer tokens
        /// and ensure that we can transfer more than `MAX_HOLDERS_BEFORE_LAUNCH` times

        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        let initial_holders_amounts = array![50.into(), 30.into(),].span();

        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        let mut index = 0;
        loop {
            if index == MAX_HOLDERS_BEFORE_LAUNCH - 2 {
                break;
            }

            // Self transfer tokens

            start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
            memecoin.transfer(initial_holder_2, 1.into());

            index += 1;
        };
    }
    #[test]
    #[should_panic(expected: ('Unruggable: max holders reached',))]
    fn test__transfer_above_holder_cap() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        let initial_holders_amounts = array![50.into(), 30.into(),].span();

        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        let mut index = 0;
        loop {
            // There are already 3 holders, so MAX_HOLDERS_BEFORE_LAUNCH - 2 should break
            if index == MAX_HOLDERS_BEFORE_LAUNCH - 1 {
                break;
            }

            // Transfer 1 token to the unique recipient
            let unique_recipient: ContractAddress = (index.into() + 9999).try_into().unwrap();
            start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
            memecoin.transfer(unique_recipient, 1.into());

            index += 1;
        };
    }
    #[test]
    fn test__transfer_no_holder_cap_after_launch() {
        let (
            owner,
            name,
            symbol,
            initial_supply,
            initial_holder_1,
            initial_holder_2,
            initial_holders,
            _
        ) =
            instantiate_params();
        let initial_holders_amounts = array![50.into(), 30.into(),].span();

        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // set owner as caller to bypass owner restrictions
        start_prank(CheatTarget::One(memecoin.contract_address), owner);

        // launch memecoin
        memecoin.launch_memecoin();

        let mut index = 0;
        loop {
            if index == MAX_HOLDERS_BEFORE_LAUNCH {
                break;
            }

            // Transfer 1 token to the unique recipient
            let unique_recipient: ContractAddress = (index.into() + 9999).try_into().unwrap();
            start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
            memecoin.transfer(unique_recipient, 1.into());

            index += 1;
        };
    }
}

