use core::debug::PrintTrait;
use core::traits::TryInto;
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, start_warp, stop_warp, CheatTarget,
    spy_events, SpyOn, EventSpy, EventAssertions
};

use starknet::{ContractAddress, contract_address_const};
use unruggable::locker::{errors, TokenLocker, ITokenLockerDispatcher, ITokenLockerDispatcherTrait};
use unruggable::tests::unit_tests::utils::{
    OWNER, deploy_eth, deploy_locker, DEFAULT_MIN_LOCKTIME, DEFAULT_LOCK_AMOUNT
};
use unruggable::tokens::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};


/// Sets up the locker contract and deploys a token contract.
/// For simplicity, the token deployed is the default "ETH" token.
fn setup() -> (ERC20ABIDispatcher, ITokenLockerDispatcher) {
    let (token, token_address) = deploy_eth();
    let locker = deploy_locker();

    (token, ITokenLockerDispatcher { contract_address: locker })
}

fn setup_and_lock(
    amount: u256, locktime: u64, withdrawer: ContractAddress
) -> (ERC20ABIDispatcher, ITokenLockerDispatcher, u128) {
    let (token, locker) = setup();

    // Approve token spending by locker
    start_prank(CheatTarget::One(token.contract_address), OWNER());
    token.approve(locker.contract_address, amount);
    stop_prank(CheatTarget::One(token.contract_address));

    start_prank(CheatTarget::One(locker.contract_address), OWNER());
    let lock_id = locker.lock_tokens(token.contract_address, amount, locktime, withdrawer);
    stop_prank(CheatTarget::One(locker.contract_address));

    (token, locker, lock_id)
}

#[test]
fn test_constructor_sets_min_locktime() {
    let (token, locker) = setup();

    let min_locktime = locker.get_min_lock_time();
    assert(min_locktime == DEFAULT_MIN_LOCKTIME, 'min_locktime is incorrect');
}

mod test_internals {
    use TokenLocker::{
        contract_state_for_testing, InternalLockerTrait, TokenLock, locksContractMemberStateTrait,
        user_locksContractMemberStateTrait
    };
    use alexandria_storage::list::{List, ListTrait};
    use core::starknet::SyscallResultTrait;
    use starknet::contract_address_const;
    use super::{TokenLocker, OWNER, start_prank, CheatTarget, stop_prank};
    use unruggable::locker::token_locker::TokenLocker::token_locks::InternalContractMemberStateTrait;
    #[test]
    fn test_assert_only_owner() {
        let mut state = contract_state_for_testing();
        let mock_lock = TokenLock {
            token: 1.try_into().unwrap(), amount: 1, unlock_time: 1, owner: OWNER(),
        };

        state.locks.write(1, mock_lock);
        let this_address = starknet::get_contract_address();
        start_prank(CheatTarget::One(this_address), OWNER());
        state.assert_only_lock_owner(1);
        stop_prank(CheatTarget::One(this_address));
    }

    #[test]
    #[should_panic(expected: ('NO ACTIVE LOCK OR NOT OWNER',))]
    fn test_assert_only_owner_not_owner() {
        let mut state = contract_state_for_testing();
        let mock_lock = TokenLock {
            token: 1.try_into().unwrap(), amount: 1, unlock_time: 1, owner: OWNER(),
        };

        state.locks.write(1, mock_lock);
        let this_address = starknet::get_contract_address();
        start_prank(CheatTarget::One(this_address), 'not_owner'.try_into().unwrap());
        state.assert_only_lock_owner(1);
        stop_prank(CheatTarget::One(this_address));
    }

    #[test]
    fn test_remove_user_lock() {
        let mut state = contract_state_for_testing();
        let user = OWNER();

        let mut lock_list = state.user_locks.read(user);
        assert(lock_list.is_empty(), 'lock list should be empty');

        lock_list.append(1);
        lock_list.append(2);
        lock_list.append(3);
        assert(lock_list.len() == 3, 'should have 3 elements');
        state.remove_lock_from_list(2, lock_list);
        lock_list = state.user_locks.read(user);
        assert(lock_list.len() == 2, 'should have 2 elements');
        assert(lock_list.array().unwrap_syscall() == array![1_u128, 3_u128], 'should have 1 and 3');

        // Check that the last element is no longer accessible
        assert(lock_list.get(2).unwrap_syscall().is_none(), 'prev len should be none');
    }
}

mod test_lock {
    use super::{
        setup, setup_and_lock, ITokenLockerDispatcher, ITokenLockerDispatcherTrait, OWNER,
        deploy_locker, start_prank, stop_prank, CheatTarget, ERC20ABIDispatcherTrait,
        DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, spy_events, SpyOn, EventSpy, EventAssertions,
        TokenLocker
    };
    use unruggable::tests::unit_tests::utils::DEFAULT_INITIAL_SUPPLY;

    #[test]
    fn test_lock_tokens() {
        // setup and lock tokens with event spy
        let (token, locker) = setup();
        start_prank(CheatTarget::One(token.contract_address), OWNER());
        token.approve(locker.contract_address, DEFAULT_LOCK_AMOUNT);
        stop_prank(CheatTarget::One(token.contract_address));

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        let mut spy = spy_events(SpyOn::One(locker.contract_address));
        let lock_id = locker
            .lock_tokens(
                token.contract_address, DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
            );
        stop_prank(CheatTarget::One(locker.contract_address));

        // Check lock details
        let lock = locker.get_lock_details(lock_id);
        assert(lock.token == token.contract_address, 'lock token is incorrect');
        assert(lock.amount == DEFAULT_LOCK_AMOUNT, 'lock amount is incorrect');
        assert(lock.unlock_time == DEFAULT_MIN_LOCKTIME, 'lock locktime is incorrect');
        assert(lock.owner == OWNER(), 'lock owner is incorrect');

        // Check token balances
        let owner_balance = token.balanceOf(OWNER());
        assert(
            owner_balance == DEFAULT_INITIAL_SUPPLY() - DEFAULT_LOCK_AMOUNT,
            'owner balance is incorrect'
        );
        let locker_balance = token.balanceOf(locker.contract_address);
        assert(locker_balance == DEFAULT_LOCK_AMOUNT, 'locker balance is incorrect');

        // Check events
        spy
            .assert_emitted(
                @array![
                    (
                        locker.contract_address,
                        TokenLocker::Event::TokenLocked(
                            TokenLocker::TokenLocked {
                                lock_id: lock_id,
                                token: token.contract_address,
                                amount: DEFAULT_LOCK_AMOUNT,
                                unlock_time: DEFAULT_MIN_LOCKTIME,
                                owner: OWNER()
                            }
                        )
                    )
                ]
            );
        assert(spy.events.len() == 0, 'There should be no events');

        // Check internal tracking of user locks
        let user_locks_length = locker.user_locks_length(OWNER());
        assert(user_locks_length == 1, 'user locks length is incorrect');
        let user_lock = locker.user_lock_at(OWNER(), 0);
        assert(user_lock == lock_id, 'user lock is incorrect');
    }

    #[test]
    #[should_panic(expected: ('LOCK TOO SHORT',))]
    fn test_lock_tokens_locktime_too_short() {
        let (token, locker, lock_id) = setup_and_lock(DEFAULT_LOCK_AMOUNT, 100, OWNER());
    }

    #[test]
    #[should_panic(expected: ('ZERO AMOUNT',))]
    fn test_lock_zero_amount() {
        let (token, locker, lock_id) = setup_and_lock(0, 100, OWNER());
    }


    #[test]
    #[should_panic(expected: ('ZERO WITHDRAWER',))]
    fn test_lock_zero_withdrawer() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, 0.try_into().unwrap()
        );
    }

    #[test]
    #[should_panic(expected: ('LOCK NOT UNIX SECONDS',))]
    fn test_lock_locktime_not_seconds() {
        let (token, locker, lock_id) = setup_and_lock(DEFAULT_LOCK_AMOUNT, 10000000001, OWNER());
    }

    #[test]
    #[should_panic(expected: ('ZERO TOKEN',))]
    fn test_lock_token_zero_address() {
        let locker = deploy_locker();
        start_prank(CheatTarget::One(locker), OWNER());
        let lock_id = ITokenLockerDispatcher { contract_address: locker }
            .lock_tokens(0.try_into().unwrap(), DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER());
        stop_prank(CheatTarget::One(locker));
    }
}

mod test_extend_lock {
    use core::traits::TryInto;
    use snforge_std::{start_warp, stop_warp};
    use super::{
        setup, setup_and_lock, ITokenLockerDispatcher, ITokenLockerDispatcherTrait, OWNER,
        deploy_locker, start_prank, stop_prank, CheatTarget, DEFAULT_LOCK_AMOUNT,
        DEFAULT_MIN_LOCKTIME, spy_events, SpyOn, EventSpy, EventAssertions, TokenLocker
    };

    #[test]
    fn test_extend_lock() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );
        let new_locktime = DEFAULT_MIN_LOCKTIME + 600;

        let mut expected_lock = locker.get_lock_details(lock_id);
        expected_lock.unlock_time = new_locktime;

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        let mut spy = spy_events(SpyOn::One(locker.contract_address));
        locker.extend_lock(lock_id, new_locktime);
        stop_prank(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock == expected_lock, 'lock locktime is incorrect');

        // Events
        spy
            .assert_emitted(
                @array![
                    (
                        locker.contract_address,
                        TokenLocker::Event::LockDurationIncreased(
                            TokenLocker::LockDurationIncreased {
                                lock_id: lock_id, new_unlock_time: new_locktime,
                            }
                        )
                    )
                ]
            );
        assert(spy.events.len() == 0, 'There should be no events');
    }

    #[test]
    #[should_panic(expected: ('NO ACTIVE LOCK OR NOT OWNER',))]
    fn test_extend_lock_not_owner() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let new_locktime = 600;
        start_prank(CheatTarget::One(locker.contract_address), 'not_owner'.try_into().unwrap());
        locker.extend_lock(lock_id, new_locktime);
        stop_prank(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock.unlock_time == new_locktime, 'lock locktime is incorrect');
    }

    #[test]
    #[should_panic(expected: ('LOCKTIME NOT INCREASED',))]
    fn test_extend_lock_locktime_not_increased() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let new_locktime = 200;
        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.extend_lock(lock_id, new_locktime);
        stop_prank(CheatTarget::One(locker.contract_address));
    }

    #[test]
    #[should_panic(expected: ('LOCK NOT UNIX SECONDS',))]
    fn test_extend_lock_locktime_not_seconds() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let new_locktime = 10000000001;
        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.extend_lock(lock_id, new_locktime);
        stop_prank(CheatTarget::One(locker.contract_address));
    }

    #[test]
    #[should_panic(expected: ('UNLOCK TIME IN PAST',))]
    fn test_extend_lock_locktime_in_past() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );
        start_warp(CheatTarget::One(locker.contract_address), 1000);
        let new_locktime = 400;
        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.extend_lock(lock_id, new_locktime);
        stop_prank(CheatTarget::One(locker.contract_address));
        stop_warp(CheatTarget::One(locker.contract_address));
    }
}

mod test_increase_lock_amount {
    use core::traits::TryInto;
    use snforge_std::{start_warp, stop_warp};
    use super::{
        setup, setup_and_lock, ITokenLockerDispatcher, ITokenLockerDispatcherTrait, OWNER,
        deploy_locker, start_prank, stop_prank, CheatTarget, ERC20ABIDispatcherTrait,
        DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, spy_events, SpyOn, EventSpy, EventAssertions,
        TokenLocker
    };

    #[test]
    fn test_increase_lock_amount() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );
        let increased_amount = 200;

        let mut expected_lock = locker.get_lock_details(lock_id);
        expected_lock.amount += increased_amount;

        // approve - increase lock
        start_prank(CheatTarget::One(token.contract_address), OWNER());
        token.approve(locker.contract_address, increased_amount);
        stop_prank(CheatTarget::One(token.contract_address));

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        let mut spy = spy_events(SpyOn::One(locker.contract_address));
        locker.increase_lock_amount(lock_id, increased_amount);
        stop_prank(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock == expected_lock, 'lock amount is incorrect');

        // Events
        spy
            .assert_emitted(
                @array![
                    (
                        locker.contract_address,
                        TokenLocker::Event::LockAmountIncreased(
                            TokenLocker::LockAmountIncreased {
                                lock_id: lock_id, amount_to_increase: increased_amount,
                            }
                        )
                    )
                ]
            );

        assert(spy.events.len() == 0, 'There should be no events');
    }

    #[test]
    #[should_panic(expected: ('NO ACTIVE LOCK OR NOT OWNER',))]
    fn test_increase_lock_amount_not_owner() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let new_amount = 200;
        start_prank(CheatTarget::One(locker.contract_address), 'not_owner'.try_into().unwrap());
        locker.increase_lock_amount(lock_id, new_amount);
        stop_prank(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock.amount == new_amount, 'lock amount is incorrect');
    }

    #[test]
    #[should_panic(expected: ('ZERO AMOUNT',))]
    fn test_increase_lock_amount_zero_amount() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let new_amount = 0;
        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.increase_lock_amount(lock_id, new_amount);
        stop_prank(CheatTarget::One(locker.contract_address));
    }
}

mod test_withdrawal {
    use core::traits::TryInto;
    use snforge_std::{start_warp, stop_warp};
    use starknet::contract_address_const;
    use super::{
        setup, setup_and_lock, ITokenLockerDispatcher, ITokenLockerDispatcherTrait, OWNER,
        deploy_locker, start_prank, stop_prank, CheatTarget, ERC20ABIDispatcherTrait,
        DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, spy_events, SpyOn, EventSpy, EventAssertions,
        TokenLocker,
    };
    use unruggable::locker::TokenLock;
    use unruggable::tests::unit_tests::utils::DEFAULT_INITIAL_SUPPLY;

    #[test]
    fn test_withdraw() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let mut expected_lock = TokenLock {
            token: contract_address_const::<0>(),
            owner: contract_address_const::<0>(),
            amount: 0,
            unlock_time: 0
        };

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        start_warp(CheatTarget::One(locker.contract_address), DEFAULT_MIN_LOCKTIME + 1);
        let mut spy = spy_events(SpyOn::One(locker.contract_address));
        locker.withdraw(lock_id);
        stop_prank(CheatTarget::One(locker.contract_address));
        stop_warp(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock == expected_lock, 'lock should be empty');

        // Events
        spy
            .assert_emitted(
                @array![
                    (
                        locker.contract_address,
                        TokenLocker::Event::TokenWithdrawn(
                            TokenLocker::TokenWithdrawn {
                                lock_id: lock_id, amount: DEFAULT_LOCK_AMOUNT,
                            }
                        )
                    ),
                    (
                        locker.contract_address,
                        TokenLocker::Event::TokenUnlocked(
                            TokenLocker::TokenUnlocked { lock_id: lock_id, }
                        )
                    )
                ]
            );

        assert(spy.events.len() == 0, 'There should be no events');
    }

    #[test]
    fn test_withdraw_one_of_many_locks() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        // approve and lock another time
        start_prank(CheatTarget::One(token.contract_address), OWNER());
        token.approve(locker.contract_address, 200);
        stop_prank(CheatTarget::One(token.contract_address));

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        let new_lock_id = locker
            .lock_tokens(token.contract_address, 200, DEFAULT_MIN_LOCKTIME, OWNER());
        stop_prank(CheatTarget::One(locker.contract_address));

        // Withdraw the first lock
        let expected_lock = TokenLock {
            token: contract_address_const::<0>(),
            owner: contract_address_const::<0>(),
            amount: 0,
            unlock_time: 0
        };

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        start_warp(CheatTarget::One(locker.contract_address), DEFAULT_MIN_LOCKTIME + 1);
        let mut spy = spy_events(SpyOn::One(locker.contract_address));
        locker.withdraw(lock_id);
        stop_prank(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock == expected_lock, 'lock should be empty');

        // Check remaining lock is correctly tracked.
        let mut expected_remaining_lock = TokenLock {
            token: token.contract_address,
            owner: OWNER(),
            amount: 200,
            unlock_time: DEFAULT_MIN_LOCKTIME
        };
        let user_locks_length = locker.user_locks_length(OWNER());
        let user_lock_id = locker.user_lock_at(OWNER(), 0);
        let remaining_lock = locker.get_lock_details(user_lock_id);

        assert(user_locks_length == 1, 'user locks length is incorrect');
        assert(user_lock_id == new_lock_id, 'user lock is incorrect');
        assert(remaining_lock == expected_remaining_lock, 'remaining lock is incorrect');
    }

    #[test]
    fn test_partial_withdraw() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let partial_amount = 50;
        let mut expected_lock = locker.get_lock_details(lock_id);
        expected_lock.amount -= partial_amount;

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        start_warp(CheatTarget::One(locker.contract_address), DEFAULT_MIN_LOCKTIME + 1);
        let mut spy = spy_events(SpyOn::One(locker.contract_address));
        locker.partial_withdraw(lock_id, partial_amount);
        stop_prank(CheatTarget::One(locker.contract_address));
        stop_warp(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock == expected_lock, 'lock amount is incorrect');

        // Events
        spy
            .assert_emitted(
                @array![
                    (
                        locker.contract_address,
                        TokenLocker::Event::TokenWithdrawn(
                            TokenLocker::TokenWithdrawn {
                                lock_id: lock_id, amount: partial_amount,
                            }
                        )
                    )
                ]
            );

        assert(spy.events.len() == 0, 'There should be no events');

        // Check token balances
        let owner_balance = token.balanceOf(OWNER());
        assert(
            owner_balance == DEFAULT_INITIAL_SUPPLY() - DEFAULT_LOCK_AMOUNT + partial_amount,
            'owner balance is incorrect'
        );
        let locker_balance = token.balanceOf(locker.contract_address);
        assert(locker_balance == expected_lock.amount, 'locker balance is incorrect');

        // Check that user position is still tracked
        let user_locks_length = locker.user_locks_length(OWNER());
        assert(user_locks_length == 1, 'user locks length is incorrect');
        let user_lock = locker.user_lock_at(OWNER(), 0);
        assert(user_lock == lock_id, 'user lock is incorrect');

        // Check that token position is still tracked
        let token_locks_length = locker.token_locks_length(lock.token);
        assert(token_locks_length == 1, 'token locks length is incorrect');
        let token_lock = locker.token_locked_at(lock.token, 0);
        assert(token_lock == lock_id, 'token lock is incorrect');
    }

    #[test]
    #[should_panic(expected: ('NO ACTIVE LOCK OR NOT OWNER',))]
    fn test_withdraw_not_owner() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        start_prank(CheatTarget::One(locker.contract_address), 'not_owner'.try_into().unwrap());
        start_warp(CheatTarget::One(locker.contract_address), DEFAULT_MIN_LOCKTIME + 1);
        locker.withdraw(lock_id);
        stop_prank(CheatTarget::One(locker.contract_address));
        stop_warp(CheatTarget::One(locker.contract_address));
    }

    #[test]
    #[should_panic(expected: ('NOT UNLOCKED YET',))]
    fn test_withdraw_lock_not_expired() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        start_warp(CheatTarget::One(locker.contract_address), 200);
        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.withdraw(lock_id);
        stop_prank(CheatTarget::One(locker.contract_address));
        stop_warp(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock.amount == 0, 'lock amount is incorrect');
    }

    #[test]
    #[should_panic(expected: ('AMOUNT EXCEEDS LOCKED',))]
    fn test_partial_withdraw_amount_too_high() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        start_warp(CheatTarget::One(locker.contract_address), DEFAULT_MIN_LOCKTIME + 1);
        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.partial_withdraw(lock_id, DEFAULT_LOCK_AMOUNT + 1);
        stop_prank(CheatTarget::One(locker.contract_address));
        stop_warp(CheatTarget::One(locker.contract_address));
    }
}

mod test_transfer_lock {
    use core::traits::TryInto;
    use snforge_std::{start_warp, stop_warp};
    use starknet::contract_address_const;
    use super::{
        setup, setup_and_lock, ITokenLockerDispatcher, ITokenLockerDispatcherTrait, OWNER,
        deploy_locker, start_prank, stop_prank, CheatTarget, ERC20ABIDispatcherTrait,
        DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, spy_events, SpyOn, EventSpy, EventAssertions,
        TokenLocker
    };
    use unruggable::locker::TokenLock;

    #[test]
    fn test_transfer_lock() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let new_owner = 'new_owner'.try_into().unwrap();
        let mut expected_lock = locker.get_lock_details(lock_id);
        expected_lock.owner = new_owner;

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        let mut spy = spy_events(SpyOn::One(locker.contract_address));
        locker.transfer_lock(lock_id, new_owner);
        stop_prank(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock == expected_lock, 'lock owner is incorrect');

        // Events
        spy
            .assert_emitted(
                @array![
                    (
                        locker.contract_address,
                        TokenLocker::Event::LockOwnershipTransferred(
                            TokenLocker::LockOwnershipTransferred {
                                lock_id: lock_id, new_owner: new_owner,
                            }
                        )
                    )
                ]
            );
        assert(spy.events.len() == 0, 'There should be no events');

        // Check internal tracking of user locks
        let new_owner_locks_length = locker.user_locks_length(new_owner);
        assert(new_owner_locks_length == 1, 'new owner length incorrect');
        let new_owner_lock = locker.user_lock_at(new_owner, 0);
        assert(new_owner_lock == lock_id, 'new owner lock is incorrect');

        // Check internal tracking of token locks
        let new_token_locks_length = locker.token_locks_length(lock.token);
        assert(new_token_locks_length == 1, 'new token length incorrect');
        let new_token_lock = locker.token_locked_at(lock.token, 0);
        assert(new_token_lock == lock_id, 'new owner lock is incorrect');

        let old_owner_locks_length = locker.user_locks_length(OWNER());
        assert(old_owner_locks_length == 0, 'old owner length is incorrect');
    }

    #[test]
    #[should_panic(expected: ('List index out of bounds',))]
    fn test_transfer_lock_old_lock_erased_from_prev_owner_list() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let new_owner = 'new_owner'.try_into().unwrap();

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.transfer_lock(lock_id, new_owner);
        stop_prank(CheatTarget::One(locker.contract_address));

        // We checked the new owner list in the previous test, so we only check the old owner list
        // which fails the test as the index is out of bounds.
        let old_owner_locks_length = locker.user_locks_length(OWNER());
        assert(old_owner_locks_length == 0, 'old owner length is incorrect');
        let old_owner_lock = locker.user_lock_at(OWNER(), 0);
        assert(old_owner_lock == 0, 'old owner lock is incorrect');
    }

    #[test]
    #[should_panic(expected: ('NO ACTIVE LOCK OR NOT OWNER',))]
    fn test_transfer_lock_not_owner() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let new_owner = 'new_owner'.try_into().unwrap();
        start_prank(CheatTarget::One(locker.contract_address), 'not_owner'.try_into().unwrap());
        locker.transfer_lock(lock_id, new_owner);
        stop_prank(CheatTarget::One(locker.contract_address));

        let lock = locker.get_lock_details(lock_id);
        assert(lock.owner == new_owner, 'lock owner is incorrect');
    }

    #[test]
    #[should_panic(expected: ('ZERO WITHDRAWER',))]
    fn test_transfer_lock_zero_new_owner() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.transfer_lock(lock_id, 0.try_into().unwrap());
        stop_prank(CheatTarget::One(locker.contract_address));
    }
}

mod test_getters {
    use super::{
        setup, setup_and_lock, ITokenLockerDispatcher, ITokenLockerDispatcherTrait, OWNER,
        deploy_locker, start_prank, stop_prank, CheatTarget, ERC20ABIDispatcherTrait,
        DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, start_warp, stop_warp, deploy_eth
    };

    #[test]
    fn test_get_remaining_time() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let remaining_locktime = locker.get_remaining_time(lock_id);
        assert(remaining_locktime == DEFAULT_MIN_LOCKTIME, 'remaining locktime is incorrect');
    }

    #[test]
    fn test_get_remaining_time_time_elapsed() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );
        let elapsed = 200;

        start_warp(CheatTarget::One(locker.contract_address), elapsed);
        let remaining_locktime = locker.get_remaining_time(lock_id);
        assert(
            remaining_locktime == DEFAULT_MIN_LOCKTIME - elapsed, 'remaining locktime is incorrect'
        );
        stop_warp(CheatTarget::One(locker.contract_address));
    }

    #[test]
    fn test_get_remaining_time_time_exceeded() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_LOCK_DEADLINE, OWNER()
        );
        let elapsed = DEFAULT_LOCK_DEADLINE + 1;

        start_warp(CheatTarget::One(locker.contract_address), elapsed);
        let remaining_locktime = locker.get_remaining_time(lock_id);
        assert(remaining_locktime == 0, 'remaining locktime is incorrect');
        stop_warp(CheatTarget::One(locker.contract_address));
    }

    #[test]
    fn test_user_locks_length() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let user_locks_length = locker.user_locks_length(OWNER());
        assert(user_locks_length == 1, 'user locks length is incorrect');

        // approve and lock another time
        start_prank(CheatTarget::One(token.contract_address), OWNER());
        token.approve(locker.contract_address, 200);
        stop_prank(CheatTarget::One(token.contract_address));

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.lock_tokens(token.contract_address, 200, DEFAULT_MIN_LOCKTIME, OWNER());
        stop_prank(CheatTarget::One(locker.contract_address));

        let new_user_locks_length = locker.user_locks_length(OWNER());
        assert(new_user_locks_length == 2, 'new user locks length incorrect');
    }

    #[test]
    fn test_user_lock_at() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_MIN_LOCKTIME, OWNER()
        );

        let user_lock = locker.user_lock_at(OWNER(), 0);
        assert(user_lock == lock_id, 'user lock is incorrect');

        // approve and lock another time
        start_prank(CheatTarget::One(token.contract_address), OWNER());
        token.approve(locker.contract_address, 200);
        stop_prank(CheatTarget::One(token.contract_address));

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        let new_lock_id = locker
            .lock_tokens(token.contract_address, 200, DEFAULT_MIN_LOCKTIME, OWNER());
        stop_prank(CheatTarget::One(locker.contract_address));

        let user_lock = locker.user_lock_at(OWNER(), 1);
        assert(user_lock == new_lock_id, 'user lock is incorrect');
    }


    #[test]
    fn test_token_locks_length() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_LOCK_DEADLINE, OWNER()
        );

        let lock = locker.get_lock_details(lock_id);

        let token_locks_length = locker.token_locks_length(token.contract_address);
        assert(token_locks_length == 1, 'token locks length is incorrect');

        // approve and lock another time
        start_prank(CheatTarget::One(token.contract_address), OWNER());
        token.approve(locker.contract_address, 200);
        stop_prank(CheatTarget::One(token.contract_address));

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        locker.lock_tokens(token.contract_address, 200, 500, OWNER());
        stop_prank(CheatTarget::One(locker.contract_address));

        let new_token_locks_length = locker.token_locks_length(token.contract_address);
        assert(new_token_locks_length == 2, 'new token locks len incorrect');
    }

    #[test]
    fn test_token_lock_at() {
        let (token, locker, lock_id) = setup_and_lock(
            DEFAULT_LOCK_AMOUNT, DEFAULT_LOCK_DEADLINE, OWNER()
        );

        let token_lock = locker.token_locked_at(token.contract_address, 0);
        assert(token_lock == lock_id, 'user lock is incorrect');

        // approve and lock another time
        start_prank(CheatTarget::One(token.contract_address), OWNER());
        token.approve(locker.contract_address, 200);
        stop_prank(CheatTarget::One(token.contract_address));

        start_prank(CheatTarget::One(locker.contract_address), OWNER());
        let new_lock_id = locker.lock_tokens(token.contract_address, 200, 500, OWNER());
        stop_prank(CheatTarget::One(locker.contract_address));

        let token_lock = locker.token_locked_at(token.contract_address, 1);
        assert(token_lock == new_lock_id, 'user lock is incorrect');
    }
}
