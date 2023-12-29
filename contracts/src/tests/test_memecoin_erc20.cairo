use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin::utils::serde::SerializedAppend;

use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, CheatTarget,
    TxInfoMock
};
use starknet::{ContractAddress, contract_address_const};
use unruggable::amm::amm::{AMM, AMMV2};
use unruggable::tests::utils::{TxInfoMockTrait};
use unruggable::tokens::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

//
// Constants
//

fn RECIPIENT() -> ContractAddress {
    return contract_address_const::<'RECIPIENT'>();
}

fn SPENDER() -> ContractAddress {
    return contract_address_const::<'RECIPIENT'>();
}

const ETH_UNIT_DECIMALS: u256 = 1000000000000000000;

//
// Setup
//

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
        owner.into(),
        'locker',
        1000.into(),
        name,
        symbol,
        initial_supply.low.into(),
        initial_supply.high.into()
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
    use core::array::SpanTrait;
    use core::debug::PrintTrait;
    use core::traits::Into;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{
        declare, ContractClassTrait, start_prank, stop_prank, start_warp, CheatTarget, TxInfoMock
    };
    use starknet::{ContractAddress, contract_address_const};
    use super::{deploy_contract, instantiate_params};
    use unruggable::tests::utils::DeployerHelper::{
        deploy_contracts, deploy_unruggable_memecoin_contract, deploy_memecoin_factory, create_eth
    };
    use unruggable::tests::utils::{DefaultTxInfoMock};
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

        // Check initial contract balance. Should be equal to 900.
        let balance = memecoin.balance_of(contract_address);
        assert(balance == 900, 'Invalid balance');
        // Check initial holder 1 balance. Should be equal to 50.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');
        // Check initial holder 2 balance. Should be equal to 50.
        let balance = memecoin.balance_of(initial_holder_1);
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
        let spender = super::SPENDER();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial allowance. Should be equal to 0.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == 0, 'Invalid allowance before');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), owner);
        memecoin.approve(spender, initial_supply);

        // Check allowance. Should be equal to initial supply.
        let allowance = memecoin.allowance(owner, spender);
        assert(allowance == initial_supply, 'Invalid allowance after');
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
        let recipient = super::RECIPIENT();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // setting tx_hash here 
        let mut tx_info: TxInfoMock = Default::default();
        tx_info.transaction_hash = Option::Some(1234);
        snforge_std::start_spoof(CheatTarget::One(memecoin.contract_address), tx_info);

        // Transfer 20 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        memecoin.transfer(recipient, 20);

        // Check balance. Should be equal to initial balance - 20.
        let initial_holder_1_balance = memecoin.balance_of(initial_holder_1);
        assert(initial_holder_1_balance == 50 - 20, 'Invalid balance holder 1');

        // Check recipient balance. Should be equal to 20.
        let recipient_balance = memecoin.balance_of(recipient);
        assert(recipient_balance == 20, 'Invalid balance recipient');
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
        let spender = super::SPENDER();
        let recipient = super::RECIPIENT();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to 50.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        memecoin.approve(spender, initial_supply);

        // setting tx_hash here 
        let mut tx_info: TxInfoMock = Default::default();
        tx_info.transaction_hash = Option::Some(1234);
        snforge_std::start_spoof(CheatTarget::One(memecoin.contract_address), tx_info);

        // Transfer 20 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), spender);
        memecoin.transfer_from(initial_holder_1, recipient, 20);

        // Check balance. Should be equal to initial balance - 20.
        let initial_holder_1_balance = memecoin.balance_of(initial_holder_1);
        assert(initial_holder_1_balance == 50 - 20, 'Invalid balance holder 1');

        // Check recipient balance. Should be equal to 20.
        let recipient_balance = memecoin.balance_of(recipient);
        assert(recipient_balance == 20, 'Invalid balance recipient');

        // Check allowance. Should be equal to initial supply - transfered amount.
        let allowance = memecoin.allowance(initial_holder_1, spender);
        assert(allowance == (initial_supply - 20), 'Invalid allowance');
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

        // Check initial contract balance. Should be equal to 900.
        let balance = memecoin.balanceOf(contract_address);
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
        let spender = super::SPENDER();
        let recipient = super::RECIPIENT();
        let contract_address =
            match deploy_contract(
                owner, name, symbol, initial_supply, initial_holders, initial_holders_amounts
            ) {
            Result::Ok(address) => address,
            Result::Err(msg) => panic(msg.panic_data),
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address };

        // Check initial balance. Should be equal to 50.
        let balance = memecoin.balance_of(initial_holder_1);
        assert(balance == 50, 'Invalid balance');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), initial_holder_1);
        memecoin.approve(spender, initial_supply);

        // setting tx_hash here 
        let mut tx_info: TxInfoMock = Default::default();
        tx_info.transaction_hash = Option::Some(1234);
        snforge_std::start_spoof(CheatTarget::One(memecoin.contract_address), tx_info);

        // Transfer 20 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), spender);
        memecoin.transferFrom(initial_holder_1, recipient, 20);

        // Check balance. Should be equal to initial balance - 20.
        let initial_holder_1_balance = memecoin.balance_of(initial_holder_1);
        assert(initial_holder_1_balance == 50 - 20, 'Invalid balance holder 1');

        // Check recipient balance. Should be equal to 20.
        let recipient_balance = memecoin.balance_of(recipient);
        assert(recipient_balance == 20, 'Invalid balance recipient');

        // Check allowance. Should be equal to initial supply - transfered amount.
        let allowance = memecoin.allowance(initial_holder_1, spender);
        assert(allowance == (initial_supply - 20), 'Invalid allowance');
    }
}
