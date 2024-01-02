//TODO(low prio): implement fallback mechanism for snake_case entrypoints
//TODO(low prio): implement a recover functions for tokens wrongly sent to the contract
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
    use unruggable::locker::errors;


    #[storage]
    struct Storage {
        min_lock_time: u64,
        lock_nonce: u128,
        locks: LegacyMap<u128, TokenLock>,
        user_locks: LegacyMap<ContractAddress, List<u128>>,
        token_locks: LegacyMap<ContractAddress, List<u128>>,
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
    impl TokenLocker of unruggable::locker::ITokenLocker<ContractState> {
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
                let mut user_locks = self.user_locks.read(owner);
                let mut token_locks =  self.token_locks.read(token_lock.token);

                // Removing user lock
                self.remove_lock_from_list(lock_id, user_locks);
                // Removing token lock
                self.remove_lock_from_list(lock_id,token_locks);
                
                self.emit(TokenUnlocked { lock_id });
            }
            self.emit(TokenWithdrawn { lock_id, amount });
        }

        fn transfer_lock(ref self: ContractState, lock_id: u128, new_owner: ContractAddress) {
            self.assert_only_lock_owner(lock_id);

            assert(new_owner.into() != 0_felt252, errors::ZERO_WITHDRAWER);
            let mut token_lock = self.locks.read(lock_id);

            // Update user locks
            let mut user_locks = self.user_locks.read(token_lock.owner);
            // Update token locks
            let mut token_locks = self.token_locks.read(token_lock.token);
            // Removing user lock
            self.remove_lock_from_list(lock_id, user_locks);
            // Removing token lock
            self.remove_lock_from_list(lock_id, token_locks);

            let mut new_owner_locks: List<u128> = self.user_locks.read(new_owner);
            new_owner_locks.append(lock_id);
            let mut new_token_locks : List<u128> =  self.token_locks.read(token_lock.token);
            new_token_locks.append(lock_id);

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

        fn token_locks_length(self: @ContractState, token: ContractAddress) -> u32 {
            let list: List<u128> = self.token_locks.read(token);
            list.len()
        }

        fn token_locked_at(self: @ContractState, token: ContractAddress, index: u32) -> u128 {
            let token_locks: List<u128> = self.token_locks.read(token);
            token_locks[index]
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

            let mut token_locks : List<u128> = self.token_locks.read(token);
            token_locks.append(lock_id).unwrap_syscall();

            ERC20ABIDispatcher { contract_address: token }
                .transferFrom(get_caller_address(), get_contract_address(), amount);

            self.emit(TokenLocked { lock_id, token, owner: withdrawer, amount, unlock_time });

            return lock_id;
        }

        /// Removes the id of a lock from the list of locks of a user.
        ///
        /// Internally, this function reads the list of locks of the specified `owner` or `tokens` from the `user_locks` and `token_locks` mapping.
        /// It then iterates over the list and replaces the specified `lock_id` with the last element of the list.
        /// The length of the list is then decremented by one, and the last element of the list is set to zero.
        fn remove_lock_from_list(self: @ContractState, lock_id: u128, mut list: List<u128>) {
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
