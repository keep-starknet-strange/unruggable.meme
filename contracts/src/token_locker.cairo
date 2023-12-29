use TokenLocker::TokenLock;
use starknet::ContractAddress;

mod errors {
    const ZERO_AMOUNT: felt252 = 'ZERO AMOUNT';
    const ZERO_TOKEN: felt252 = 'ZERO TOKEN';
    const ZERO_WITHDRAWER: felt252 = 'ZERO WITHDRAWER';
    const LOCK_TOO_SHORT: felt252 = 'LOCK TOO SHORT';
    const LOCKTIME_NOT_INCREASED: felt252 = 'LOCKTIME NOT INCREASED';
    const LOCK_NOT_IN_SECONDS: felt252 = 'LOCK NOT UNIX SECONDS';
    const UNLOCK_IN_PAST: felt252 = 'UNLOCK TIME IN PAST';
    const WITHDRAW_AMOUNT_TOO_HIGH: felt252 = 'AMOUNT EXCEEDS LOCKED';
    const NOT_LOCK_OWNER: felt252 = 'NO ACTIVE LOCK OR NOT OWNER';
    const STILL_LOCKED: felt252 = 'NOT UNLOCKED YET';
}

#[starknet::interface]
trait ITokenLocker<TContractState> {
    // External

    /// Locks a specified amount of tokens until a specified unlock time.
    ///
    /// This function locks a specified `amount` of tokens of address `token` until the `unlock_time`.
    /// The tokens can be withdrawn by the `withdrawer` after the `unlock_time`.
    ///
    /// # Arguments
    ///
    /// * `token` - The address of the token to lock.
    /// * `amount` - The amount of tokens to be locked.
    /// * `unlock_time` - The unix time (in seconds) when the tokens can be unlocked.
    /// * `withdrawer` - The address of the contract that can withdraw the tokens after the `unlock_time`.
    ///
    /// # Returns
    ///
    /// * `u128` - The internal id of the lock.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    ///
    /// * `amount` is zero (error code: `errors::ZERO_AMOUNT`).
    /// * `token` is zero (error code: `errors::ZERO_TOKEN`).
    /// * `withdrawer` is zero (error code: `errors::ZERO_WITHDRAWER`).
    /// * `unlock_time` is not in seconds (error code: `errors::LOCK_NOT_IN_SECONDS`).
    /// * `unlock_time` is less than the current block timestamp plus the minimum lock time (error code: `errors::LOCK_TOO_SHORT`).
    ///
    fn lock_tokens(
        ref self: TContractState,
        token: ContractAddress,
        amount: u256,
        unlock_time: u64,
        withdrawer: ContractAddress
    ) -> u128;

    /// Extends the unlock time of a specified lock.
    ///
    /// This function extends the `unlock_time` of the `TokenLock` instance with the specified `lock_id`.
    /// It first ensures that the caller is the owner of the lock.
    /// It then asserts that the `new_unlock_time` is not in the past and is less than 10000000000.
    /// The function then reads the `TokenLock` from the `locks` mapping, asserts that the `new_unlock_time` is greater than the current `unlock_time`, and updates the `unlock_time`.
    /// Finally, it writes the updated `TokenLock` back to the `locks` mapping and emits a `LockDurationIncreased` event.
    ///
    /// # Arguments
    ///
    /// * `lock_id` - The ID of the lock.
    /// * `new_unlock_time` - The new unlock time.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    ///
    /// * The caller's address is not the same as the `owner` of the `TokenLock` (error code: `errors::NOT_LOCK_OWNER`).
    /// * `new_unlock_time` is less than the current block timestamp (error code: `errors::UNLOCK_IN_PAST`).
    /// * `new_unlock_time` is greater than or equal to 10000000000 (error code: `errors::LOCK_NOT_IN_SECONDS`).
    /// * `new_unlock_time` is less than or equal to the current `unlock_time` of the `TokenLock` (error code: `errors::LOCKTIME_NOT_INCREASED`).
    ///
    fn extend_lock(ref self: TContractState, lock_id: u128, new_unlock_time: u64);

    /// Increases the amount of tokens in a specified lock.
    ///
    /// This function increases the `amount` of the `TokenLock` instance with the specified `lock_id`.
    /// It first ensures that the caller is the owner of the lock.
    /// It then asserts that the `amount_to_increase` is not zero.
    /// The function then reads the `TokenLock` from the `locks` mapping, increases the `amount`, and writes the updated `TokenLock` back to the `locks` mapping.
    /// It then transfers the `amount_to_increase` of tokens from the caller to the contract.
    /// Finally, it emits a `LockAmountIncreased` event.
    ///
    /// # Arguments
    ///
    /// * `lock_id` - The ID of the lock.
    /// * `amount_to_increase` - The amount by which to increase the lock.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    ///
    /// * The caller's address is not the same as the `owner` of the `TokenLock` (error code: `errors::NOT_LOCK_OWNER`).
    /// * `amount_to_increase` is zero (error code: `errors::ZERO_AMOUNT`).
    /// * The `transferFrom` call to the ERC20 token contract fails.
    ///
    fn increase_lock_amount(ref self: TContractState, lock_id: u128, amount_to_increase: u256,);

    /// Withdraws all tokens from a specified lock.
    ///
    /// Equivalent to calling `partial_withdraw` with the `amount` equal to the `amount` of the `TokenLock`.
    fn withdraw(ref self: TContractState, lock_id: u128);

    /// Withdraws tokens from a specified lock.
    ///
    /// This function allows the owner of a lock to withdraw a specified `amount` of tokens from the lock.
    /// It first ensures that the caller is the owner of the lock.
    /// It then asserts that the `amount` is not greater than the `amount` of the `TokenLock` and that the current block timestamp is not less than the `unlock_time` of the `TokenLock`.
    /// The function then reads the `TokenLock` from the `locks` mapping, decreases the `amount`, and writes the updated `TokenLock` back to the `locks` mapping.
    /// It then transfers the `amount` of tokens from the contract to the owner.
    /// If the `amount` of the `TokenLock` is now zero, it emits a `TokenUnlocked` event.
    /// Finally, it emits a `TokenWithdrawn` event.
    ///
    /// # Arguments
    ///
    /// * `lock_id` - The ID of the lock.
    /// * `amount` - The amount of tokens to withdraw.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    ///
    /// * The caller's address is not the same as the `owner` of the `TokenLock` (error code: `errors::NOT_LOCK_OWNER`).
    /// * `amount` is greater than the `amount` of the `TokenLock` (error code: `errors::WITHDRAW_AMOUNT_TOO_HIGH`).
    /// * The current block timestamp is less than the `unlock_time` of the `TokenLock` (error code: `errors::STILL_LOCKED`).
    /// * The `transfer` call to the ERC20 token contract fails.
    ///
    fn partial_withdraw(ref self: TContractState, lock_id: u128, amount: u256);

    /// Transfers the ownership of a specified lock to a new owner.
    ///
    /// This function allows the owner of a lock to transfer the ownership to a `new_owner`.
    /// It first ensures that the caller is the owner of the lock.
    /// It then asserts that the `new_owner` is not zero.
    /// The function then reads the `TokenLock` from the `locks` mapping, updates the `owner`, and writes the updated `TokenLock` back to the `locks` mapping.
    /// Finally, it emits a `LockOwnershipTransferred` event.
    ///
    /// # Arguments
    ///
    /// * `lock_id` - The ID of the lock.
    /// * `new_owner` - The address of the new owner.
    ///
    /// # Panics
    ///
    /// This function will panic if:
    ///
    /// * The caller's address is not the same as the `owner` of the `TokenLock` (error code: `errors::NOT_LOCK_OWNER`).
    /// * `new_owner` is zero (error code: `errors::ZERO_WITHDRAWER`).
    ///
    fn transfer_lock(ref self: TContractState, lock_id: u128, new_owner: ContractAddress);

    // View

    /// Retrieves the details of a specified lock.
    ///
    /// # Arguments
    ///
    /// * `self` - A reference to the `ContractState` instance.
    /// * `lock_id` - The ID of the lock.
    ///
    /// # Returns
    ///
    /// * `TokenLock` - The details of the lock, including the `token` address, the `owner` address, the `amount` of tokens locked, and the `unlock_time`.
    ///
    fn get_lock_details(self: @TContractState, lock_id: u128) -> TokenLock;

    /// Retrieves the remaining time until a specified lock can be unlocked.
    ///
    /// # Arguments
    ///
    /// * `lock_id` - The ID of the lock.
    ///
    /// # Returns
    ///
    /// * `u64` - The remaining time until the lock can be unlocked, or 0 if the unlock time has passed or the lock does not exist.
    ///
    fn get_remaining_time(self: @TContractState, lock_id: u128) -> u64;

    /// Retrieves the minimum lock time of the contract.
    fn get_min_lock_time(self: @TContractState) -> u64;

    /// Retrieves the number of locks owned by a specified user.
    ///
    /// # Arguments
    ///
    /// * `user` - The address of the user.
    ///
    /// # Returns
    ///
    /// * `u32` - The number of locks owned by the user.
    fn user_locks_length(self: @TContractState, user: ContractAddress) -> u32;

    /// Retrieves the ID of a lock owned by a specified user.
    ///
    /// # Arguments
    ///
    /// * `user` - The address of the user.
    /// * `index` - The index of the lock in the list of locks owned by the user.
    ///
    /// # Returns
    ///
    /// * `u128` - The ID of the lock.
    fn user_lock_at(self: @TContractState, user: ContractAddress, index: u32) -> u128;
}

//TODO(low prio): implement fallback mechanism for snake_case entrypoints
//TODO(low prio): implement a recover functions for tokens wrongly sent to the contract
//TODO(high prio): keep a list of all active locks per users.
#[starknet::contract]
mod TokenLocker {
    use alexandria_storage::list::{List, ListTrait};
    use core::starknet::SyscallResultTrait;
    use core::starknet::event::EventEmitter;
    use core::traits::TryInto;
    use debug::PrintTrait;
    use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::{
        ContractAddress, contract_address_const, get_caller_address, get_contract_address,
        get_block_timestamp, Store
    };
    use super::errors;


    #[storage]
    struct Storage {
        min_lock_time: u64,
        lock_nonce: u128,
        locks: LegacyMap<u128, TokenLock>,
        user_locks: LegacyMap<ContractAddress, List<u128>>,
    }


    /// Events

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TokenLocked: TokenLocked,
        TokenUnlocked: TokenUnlocked,
        TokenWithdrawn: TokenWithdrawn,
        LockOwnershipTransferred: LockOwnershipTransferred,
        LockDurationIncreased: LockDurationIncreased,
        LockAmountIncreased: LockAmountIncreased
    }

    #[derive(Drop, starknet::Event)]
    struct TokenLocked {
        #[key]
        lock_id: u128,
        token: ContractAddress,
        owner: ContractAddress,
        amount: u256,
        unlock_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct TokenUnlocked {
        #[key]
        lock_id: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct TokenWithdrawn {
        #[key]
        lock_id: u128,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct LockOwnershipTransferred {
        #[key]
        lock_id: u128,
        new_owner: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct LockDurationIncreased {
        #[key]
        lock_id: u128,
        new_unlock_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct LockAmountIncreased {
        lock_id: u128,
        amount_to_increase: u256
    }

    #[derive(Drop, Copy, starknet::Store, Serde, PartialEq)]
    struct TokenLock {
        token: ContractAddress,
        owner: ContractAddress,
        amount: u256,
        unlock_time: u64,
    }

    /// Initializes a new instance of a TokenLocker contract.  The constructor
    /// sets the minimum lock time for all locks created by this contract.
    ///
    /// # Arguments
    ///
    /// * `min_lock_time` - The minimum lock time applicable to all locks
    ///  created by this contract.
    #[constructor]
    fn constructor(ref self: ContractState, min_lock_time: u64,) {
        self.min_lock_time.write(min_lock_time);
    }

    #[abi(embed_v0)]
    impl TokenLocker of super::ITokenLocker<ContractState> {
        fn lock_tokens(
            ref self: ContractState,
            token: ContractAddress,
            amount: u256,
            unlock_time: u64,
            withdrawer: ContractAddress
        ) -> u128 {
            //TODO(safety): Add a check to verify that the token locked is an LP pair - to avoid people locking tokens
            // unintentionally

            assert(amount != 0, errors::ZERO_AMOUNT);
            assert(token.into() != 0_felt252, errors::ZERO_TOKEN);
            assert(withdrawer.into() != 0_felt252, errors::ZERO_WITHDRAWER);
            assert(unlock_time < 10000000000, errors::LOCK_NOT_IN_SECONDS);
            assert(
                unlock_time >= get_block_timestamp() + self.min_lock_time.read(),
                errors::LOCK_TOO_SHORT
            );

            self._proceed_lock(token, withdrawer, amount, unlock_time)
        }

        fn extend_lock(ref self: ContractState, lock_id: u128, new_unlock_time: u64) {
            self.assert_only_lock_owner(lock_id);

            assert(new_unlock_time >= get_block_timestamp(), errors::UNLOCK_IN_PAST);
            assert(new_unlock_time < 10000000000, errors::LOCK_NOT_IN_SECONDS);

            let mut token_lock = self.locks.read(lock_id);
            assert(new_unlock_time > token_lock.unlock_time, errors::LOCKTIME_NOT_INCREASED);
            token_lock.unlock_time = new_unlock_time;
            self.locks.write(lock_id, token_lock);

            self.emit(LockDurationIncreased { lock_id, new_unlock_time });
        }

        fn increase_lock_amount(ref self: ContractState, lock_id: u128, amount_to_increase: u256) {
            self.assert_only_lock_owner(lock_id);

            assert(amount_to_increase != 0, errors::ZERO_AMOUNT);
            let mut token_lock = self.locks.read(lock_id);
            token_lock.amount += amount_to_increase;
            self.locks.write(lock_id, token_lock);

            ERC20ABIDispatcher { contract_address: token_lock.token }
                .transferFrom(get_caller_address(), get_contract_address(), amount_to_increase);
            self.emit(LockAmountIncreased { lock_id, amount_to_increase });
        }

        fn withdraw(ref self: ContractState, lock_id: u128) {
            let token_lock = self.locks.read(lock_id);
            self.partial_withdraw(lock_id, token_lock.amount);
        }

        fn partial_withdraw(ref self: ContractState, lock_id: u128, amount: u256) {
            self.assert_only_lock_owner(lock_id);

            let mut token_lock = self.locks.read(lock_id);
            assert(amount <= token_lock.amount, errors::WITHDRAW_AMOUNT_TOO_HIGH);
            assert(get_block_timestamp() >= token_lock.unlock_time, errors::STILL_LOCKED);

            // Effects
            let owner = token_lock.owner;
            token_lock.amount -= amount;
            self.locks.write(lock_id, token_lock);

            // Interactions
            ERC20ABIDispatcher { contract_address: token_lock.token }.transfer(owner, amount);

            if token_lock.amount == 0 {
                self
                    .locks
                    .write(
                        lock_id,
                        TokenLock {
                            token: contract_address_const::<0>(),
                            owner: contract_address_const::<0>(),
                            amount: 0,
                            unlock_time: 0
                        }
                    );
                self.remove_user_lock(lock_id, owner);
                self.emit(TokenUnlocked { lock_id });
            }
            self.emit(TokenWithdrawn { lock_id, amount });
        }

        fn transfer_lock(ref self: ContractState, lock_id: u128, new_owner: ContractAddress) {
            self.assert_only_lock_owner(lock_id);

            assert(new_owner.into() != 0_felt252, errors::ZERO_WITHDRAWER);
            let mut token_lock = self.locks.read(lock_id);

            // Update user locks
            self.remove_user_lock(lock_id, token_lock.owner);
            let mut new_owner_locks: List<u128> = self.user_locks.read(new_owner);
            new_owner_locks.append(lock_id);

            // Update lock details
            token_lock.owner = new_owner;
            self.locks.write(lock_id, token_lock);

            self.emit(LockOwnershipTransferred { lock_id: lock_id, new_owner });
        }

        fn get_lock_details(self: @ContractState, lock_id: u128) -> TokenLock {
            let token_lock = self.locks.read(lock_id);
            token_lock
        }

        fn get_remaining_time(self: @ContractState, lock_id: u128) -> u64 {
            let token_lock = self.locks.read(lock_id);
            let remaining_time = token_lock.unlock_time - get_block_timestamp();
            if remaining_time > 0 {
                return remaining_time;
            } else {
                return 0;
            }
        }

        fn get_min_lock_time(self: @ContractState) -> u64 {
            self.min_lock_time.read()
        }

        fn user_locks_length(self: @ContractState, user: ContractAddress) -> u32 {
            let user_locks: List<u128> = self.user_locks.read(user);
            user_locks.len
        }

        fn user_lock_at(self: @ContractState, user: ContractAddress, index: u32) -> u128 {
            let user_locks: List<u128> = self.user_locks.read(user);
            user_locks[index]
        }
    }

    #[generate_trait]
    impl InternalLockerImpl of InternalLockerTrait {
        /// Ensures that the caller is the owner of the specified lock.
        ///
        /// # Arguments
        ///
        /// * `lock_id` - The ID of the lock.
        ///
        /// # Panics
        ///
        /// This function will panic if:
        ///
        /// * The caller's address is not the same as the `owner` of the `TokenLock` (error code: `errors::NOT_LOCK_OWNER`).
        ///
        fn assert_only_lock_owner(self: @ContractState, lock_id: u128) {
            let token_lock = self.locks.read(lock_id);
            assert(get_caller_address() == token_lock.owner, errors::NOT_LOCK_OWNER);
        }

        /// Performs the logic to lock the tokens.
        ///
        /// This function creates a `TokenLock` instance and writes it to the `locks` mapping of the contract.
        /// It also increments the `lock_nonce` of the contract, which represents the amount of locks created.
        /// The function then transfers the specified `amount` of tokens from the caller to the contract.
        /// Finally, it emits a `TokenLocked` event.
        ///
        /// # Arguments
        ///
        /// * `token` - The address of the token contract.
        /// * `withdrawer` - The address that can withdraw the tokens after the `unlock_time`.
        /// * `amount` - The amount of tokens to be locked.
        /// * `unlock_time` - The time (in seconds) when the tokens can be unlocked.
        ///
        /// # Returns
        ///
        /// * `u128` - The ID of the new lock.
        ///
        /// # Panics
        ///
        /// This function will panic if:
        ///
        /// * The `transferFrom` call to the ERC20 token contract fails.
        ///
        fn _proceed_lock(
            ref self: ContractState,
            token: ContractAddress,
            withdrawer: ContractAddress,
            amount: u256,
            unlock_time: u64
        ) -> u128 {
            let token_lock = TokenLock {
                token, owner: withdrawer, amount: amount, unlock_time: unlock_time
            };

            let lock_id = self.lock_nonce.read() + 1;
            self.lock_nonce.write(lock_id);
            self.locks.write(lock_id, token_lock);

            let mut user_locks: List<u128> = self.user_locks.read(withdrawer);
            user_locks.append(lock_id).unwrap_syscall();

            ERC20ABIDispatcher { contract_address: token }
                .transferFrom(get_caller_address(), get_contract_address(), amount);

            self.emit(TokenLocked { lock_id, token, owner: withdrawer, amount, unlock_time });

            return lock_id;
        }

        /// Removes the id of a lock from the list of locks of a user.
        ///
        /// Internally, this function reads the list of locks of the specified `owner` from the `user_locks` mapping.
        /// It then iterates over the list and replaces the specified `lock_id` with the last element of the list.
        /// The length of the list is then decremented by one, and the last element of the list is set to zero.
        fn remove_user_lock(self: @ContractState, lock_id: u128, owner: ContractAddress) {
            let mut list = self.user_locks.read(owner);
            let list_len = list.len();
            let mut i = 0;
            loop {
                if i == list_len {
                    break;
                }
                let current_lock_id = list[i];
                if current_lock_id == lock_id {
                    let last_element = list[list_len - 1];
                    list.set(i, last_element);
                    list.set(list_len - 1, 0);
                    list.len -= 1;
                    Store::write(list.address_domain, list.base, list.len).unwrap_syscall();
                    break;
                }
                i += 1;
            }
        }
    }
}
