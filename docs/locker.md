# Unruggable Locker

## 📝 Description

The Unruggable Locker is a smart contract that allows you to lock your ERC20 LP tokens for a certain amount of time. It is designed to be used with the [Unruggable Framework](https://unruggable.meme/) to lock liquidity for a certain amount of time when launching a token. As long as the liquidity is locked, the LP tokens cannot be removed from the liquidity pool.

The Unruggable locker locks user's LP tokens for a custom amount of time. This amount of time must be greater than the minimum lock period, which is set during deployment by the deployer.
You can see the minimum lock period by calling the `get_min_lock_time` function.

## Features

- Lock ERC20 LP tokens for a certain amount of time
- Unlock tokens after the lock period has passed (partial or total amount)
- Transfer locked ownership to another address
- Increase the lock period for an existing lock
- Increase the amount of tokens locked for an existing lock
- Track a user's locked tokens and the details of each lock

## How it works

This contract can be used to lock ERC20 tokens for a certain amount of time. The contract will transfer the tokens from your address to the contract, create a lock, and assign this lock, identified by a unique `id` to your address.
Once locked, the tokens cannot be withdrawn until the lock period has passed. Once the lock period has passed, you can withdraw the tokens by calling the `withdraw` function with the `id` of the lock you want to withdraw from.

### Locking tokens

To lock tokens, you need to call the `lock_tokens` function with the following parameters:
- `token`: The address of the ERC20 token to lock
- `amount`: The amount of tokens to lock
- `unlock_time`: The timestamp when the tokens will be unlocked. This timestamp must be in the future, and expressed in seconds since the Unix epoch.
- `withdrawer`: The address that will be able to withdraw the tokens after the unlock time has passed. This address can be different from the caller's address.

This will transfer the tokens from the caller's address to the contract, and increase the amount of tokens locked for the given lock. Therefore, the caller must have approved the contract to transfer the tokens on their behalf.

### Retrieving lock details

To retrieve the details of a lock, you need to call the `get_lock_details` function with the id of the lock you want to retrieve.
This `id` is internally generated when locking tokens. The contract keeps track of the locks created by each user.
You can see how many locks a user has by calling the `user_locks_length` function. This will return the number of locks a user has.
You can then retrieve the id of a lock by calling the `user_lock_at` function with the index of the lock you want to retrieve.

For example, if a user has 3 locks, the `user_locks_length` function will return `3`. If you want to retrieve the details of the second lock, you need to call the `user_lock_at` function with the index `1` (the index starts at `0`).

### Unlocking tokens

Once the lock period has passed, the tokens can be withdrawn by calling either the `withdraw` or the `partial_withdraw` functions.
The `withdraw` function will withdraw all the tokens locked for the given token, while the `partial_withdraw` function will withdraw a certain amount of tokens.

To withdraw all the tokens locked for a given token, you need to call the `withdraw` function with the id of the lock you want to withdraw from.
This `id` is internally generated when locking tokens, and can be retrieved by using the `user_lock_at` function.

### Increasing the lock period

To increase the lock period of a lock, you need to call the `extend_lock` function with the id of the lock you want to increase the lock period of, and the new unlock time.
This new unlock time must be in the future, and expressed in seconds since the Unix epoch. It must also be greater than the current unlock time.

### Increasing the amount of tokens locked

To increase the amount of tokens locked for a given lock, you need to call the `increase_lock_amount` function with the id of the lock you want to increase the amount of tokens locked for, and the amount of tokens to add to the lock.
This will transfer the tokens from the caller's address to the contract, and increase the amount of tokens locked for the given lock. Therefore, the caller must have approved the contract to transfer the tokens on their behalf.
