use openzeppelin::token::erc20::interface::{IERC20, IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin::utils::serde::SerializedAppend;

use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, RevertedTransaction, CheatTarget,
    TxInfoMock
};
use starknet::{ContractAddress, contract_address_const};
use unruggable::exchanges::{SupportedExchanges};
use unruggable::tests::unit_tests::utils::{
    OWNER, NAME, SYMBOL, DEFAULT_INITIAL_SUPPLY, RECIPIENT, SPENDER, deploy_locker, INITIAL_HOLDERS,
    INITIAL_HOLDERS_AMOUNTS, TRANSFER_RESTRICTION_DELAY, DefaultTxInfoMock,
    deploy_standalone_memecoin
};
use unruggable::token::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};


mod erc20_metadata {
    use core::debug::PrintTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
    use starknet::{ContractAddress, contract_address_const};
    use super::{
        deploy_standalone_memecoin, OWNER, NAME, SYMBOL, DEFAULT_INITIAL_SUPPLY, RECIPIENT, SPENDER,
        deploy_locker
    };
    use unruggable::token::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    #[test]
    fn test_name() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();
        assert(memecoin.name() == NAME(), 'Invalid name');
    }

    #[test]
    fn test_decimals() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();
        assert(memecoin.decimals() == 18, 'Invalid decimals');
    }

    #[test]
    fn test_symbol() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();
        assert(memecoin.symbol() == SYMBOL(), 'Invalid symbol');
    }
}

mod erc20_entrypoints {
    use core::array::SpanTrait;
    use core::debug::PrintTrait;
    use core::traits::Into;
    use snforge_std::{
        declare, ContractClassTrait, start_prank, stop_prank, start_warp, CheatTarget, TxInfoMock
    };
    use starknet::{ContractAddress, contract_address_const};
    use super::{
        deploy_standalone_memecoin, OWNER, NAME, SYMBOL, DEFAULT_INITIAL_SUPPLY, RECIPIENT, SPENDER,
        deploy_locker, INITIAL_HOLDERS, DefaultTxInfoMock, INITIAL_HOLDERS_AMOUNTS
    };
    use unruggable::token::interface::{
        IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
    };

    // Test ERC20 snake entrypoints

    #[test]
    fn test_total_supply() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();
        assert(memecoin.total_supply() == DEFAULT_INITIAL_SUPPLY(), 'Invalid total supply');
    }

    #[test]
    fn test_balance_of() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();
        let holders_sum = *INITIAL_HOLDERS_AMOUNTS()[0] + *INITIAL_HOLDERS_AMOUNTS()[1];

        // Check initial contract balance and initial holders balances.
        assert(
            memecoin.balance_of(snforge_std::test_address()) == DEFAULT_INITIAL_SUPPLY()
                - holders_sum,
            'Invalid balance memecoin'
        );
        assert(
            memecoin.balance_of(*INITIAL_HOLDERS()[0]) == *INITIAL_HOLDERS_AMOUNTS()[0],
            'Invalid balance holder1'
        );
        assert(
            memecoin.balance_of(*INITIAL_HOLDERS()[1]) == *INITIAL_HOLDERS_AMOUNTS()[1],
            'Invalid balance holder2'
        );
    }

    #[test]
    fn test_approve_allowance() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();

        // Check initial allowance. Should be equal to 0.
        let allowance = memecoin.allowance(OWNER(), SPENDER());
        assert(allowance == 0, 'Invalid allowance before');

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), OWNER());
        memecoin.approve(SPENDER(), DEFAULT_INITIAL_SUPPLY());

        // Check allowance. Should be equal to initial supply.
        let allowance = memecoin.allowance(OWNER(), SPENDER());
        assert(allowance == DEFAULT_INITIAL_SUPPLY(), 'Invalid allowance after');
    }

    #[test]
    fn test_transfer() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();

        // Transfer 20 tokens to recipient.
        let pre_sender_balance = memecoin.balance_of(*INITIAL_HOLDERS()[0]);
        start_prank(CheatTarget::One(memecoin.contract_address), *INITIAL_HOLDERS()[0]);
        memecoin.transfer(RECIPIENT(), 20);

        // Check balance. Should be equal to initial balance - 20.
        let post_sender_balance = memecoin.balance_of(*INITIAL_HOLDERS()[0]);
        assert(post_sender_balance == pre_sender_balance - 20, 'Invalid sender balance update');

        // Check recipient balance. Should be equal to 20.
        let recipient_balance = memecoin.balance_of(RECIPIENT());
        assert(recipient_balance == 20, 'Invalid balance recipient');
    }

    #[test]
    fn test_transfer_from() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();
        let pre_sender_balance = memecoin.balance_of(*INITIAL_HOLDERS()[0]);

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), *INITIAL_HOLDERS()[0]);
        memecoin.approve(SPENDER(), DEFAULT_INITIAL_SUPPLY());

        // Transfer 20 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), SPENDER());
        memecoin.transfer_from(*INITIAL_HOLDERS()[0], RECIPIENT(), 20);

        // Check balance. Should be equal to initial balance - 20.
        let post_sender_balance = memecoin.balance_of(*INITIAL_HOLDERS()[0]);
        assert(post_sender_balance == pre_sender_balance - 20, 'Invalid sender balance update');

        // Check recipient balance. Should be equal to 20.
        let recipient_balance = memecoin.balanceOf(RECIPIENT());
        assert(recipient_balance == 20, 'Invalid balance recipient');

        // Check allowance. Should be equal to initial supply - transfered amount.
        let allowance = memecoin.allowance(*INITIAL_HOLDERS()[0], SPENDER());
        assert(allowance == (DEFAULT_INITIAL_SUPPLY() - 20), 'Invalid allowance');
    }

    // Test ERC20 Camel entrypoints

    #[test]
    fn test_totalSupply() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();
        assert(memecoin.totalSupply() == DEFAULT_INITIAL_SUPPLY(), 'Invalid total supply');
    }

    #[test]
    fn test_balanceOf() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();
        let holders_sum = *INITIAL_HOLDERS_AMOUNTS()[0] + *INITIAL_HOLDERS_AMOUNTS()[1];

        // Check initial contract balance and initial holders balances.
        assert(
            memecoin.balanceOf(snforge_std::test_address()) == DEFAULT_INITIAL_SUPPLY()
                - holders_sum,
            'Invalid balance memecoin'
        );
        assert(
            memecoin.balance_of(*INITIAL_HOLDERS()[0]) == *INITIAL_HOLDERS_AMOUNTS()[0],
            'Invalid balance holder1'
        );
        assert(
            memecoin.balance_of(*INITIAL_HOLDERS()[1]) == *INITIAL_HOLDERS_AMOUNTS()[1],
            'Invalid balance holder2'
        );
    }

    #[test]
    fn test_transferFrom() {
        let (memecoin, memecoin_address) = deploy_standalone_memecoin();
        let pre_sender_balance = memecoin.balance_of(*INITIAL_HOLDERS()[0]);

        // Approve initial supply tokens.
        start_prank(CheatTarget::One(memecoin.contract_address), *INITIAL_HOLDERS()[0]);
        memecoin.approve(SPENDER(), DEFAULT_INITIAL_SUPPLY());

        // Transfer 20 tokens to recipient.
        start_prank(CheatTarget::One(memecoin.contract_address), SPENDER());
        memecoin.transferFrom(*INITIAL_HOLDERS()[0], RECIPIENT(), 20);

        // Check balance. Should be equal to initial balance - 20.
        let post_sender_balance = memecoin.balance_of(*INITIAL_HOLDERS()[0]);
        assert(post_sender_balance == pre_sender_balance - 20, 'Invalid sender balance update');

        // Check recipient balance. Should be equal to 20.
        let recipient_balance = memecoin.balanceOf(RECIPIENT());
        assert(recipient_balance == 20, 'Invalid balance recipient');

        // Check allowance. Should be equal to initial supply - transfered amount.
        let allowance = memecoin.allowance(*INITIAL_HOLDERS()[0], SPENDER());
        assert(allowance == (DEFAULT_INITIAL_SUPPLY() - 20), 'Invalid allowance');
    }
}
