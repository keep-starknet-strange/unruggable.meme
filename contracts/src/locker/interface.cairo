use starknet::ContractAddress;
use super::TokenLocker::TokenLock;

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

    /// Retrieves the number of locks associated with a specified token.
    ///
    /// This function returns the total number of locks that have been created for a given token.
    /// It reads the length of the lock list associated with the token address from the `token_locks` mapping.
    ///
    /// # Arguments
    ///
    /// * `token` - The address of the token contract.
    ///
    /// # Returns
    ///
    /// * `u32` - The number of locks associated with the specified token.
    ///
    fn token_locks_length(self: @TContractState, token: ContractAddress) -> u32;

    /// Retrieves the ID of a lock associated with a specified token at a given index.
    ///
    /// This function returns the lock ID for a specific token based on the provided index.
    /// It reads the list of lock IDs from the `token_locks` mapping and returns the lock ID at the specified index.
    /// If the index is out of bounds, the function panics.
    ///
    /// # Arguments
    ///
    /// * `token` - The address of the token contract.
    /// * `index` - The index of the lock in the token's lock list.
    ///
    /// # Returns
    ///
    /// * `u128` - The ID of the lock at the given index for the specified token.
    /// If the index is out of bounds, the function panics.
    ///
    fn token_locked_at(self: @TContractState, token: ContractAddress, index: u32) -> u128;
}
