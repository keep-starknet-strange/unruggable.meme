use ekubo::interfaces::core::{SwapParameters};
use ekubo::types::delta::{Delta};
use ekubo::types::keys::{PoolKey};
use starknet::{ContractAddress};

#[starknet::interface]
trait ISimpleSwapper<TStorage> {
    // Execute a swap against a single pool. The tokens must already be transferred to this contract.
    fn swap(
        ref self: TStorage,
        pool_key: PoolKey,
        swap_params: SwapParameters,
        recipient: ContractAddress,
        calculated_amount_threshold: u128,
    ) -> Delta;

    // Clear the balance held by this contract. Used for collecting remaining tokens after a swap.
    fn clear(ref self: TStorage, token: ContractAddress) -> u256;
}

#[starknet::contract]
mod SimpleSwapper {
    use array::{Array, ArrayTrait, SpanTrait};

    use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait, ILocker};
    use ekubo::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
    use ekubo::shared_locker::{consume_callback_data, call_core_with_callback};
    use option::{OptionTrait};
    use result::{ResultTrait};
    use starknet::syscalls::{call_contract_syscall};

    use starknet::{get_caller_address, get_contract_address};
    use super::{ContractAddress, PoolKey, Delta, ISimpleSwapper, SwapParameters};
    use traits::{Into};
    use zeroable::{Zeroable};

    #[storage]
    struct Storage {
        core: ICoreDispatcher,
    }

    #[constructor]
    fn constructor(ref self: ContractState, core: ICoreDispatcher) {
        self.core.write(core);
    }

    #[derive(Drop, Copy, Serde)]
    struct SwapCallbackData {
        pool_key: PoolKey,
        swap_params: SwapParameters,
        recipient: ContractAddress,
        calculated_amount_threshold: u128,
    }

    #[external(v0)]
    impl LockerImpl of ILocker<ContractState> {
        fn locked(ref self: ContractState, id: u32, data: Array<felt252>) -> Array<felt252> {
            let core = self.core.read();

            let callback = consume_callback_data::<SwapCallbackData>(core, data);

            let delta = core.swap(callback.pool_key, callback.swap_params);

            let increasing = callback.swap_params.amount.sign ^ callback.swap_params.is_token1;

            // check the result of the swap exceeds the threshold
            if callback.swap_params.amount.sign {
                // if exact output, the limit is a maximum amount in
                if callback.swap_params.is_token1 {
                    assert(
                        delta.amount0.mag <= callback.calculated_amount_threshold, 'MAX_AMOUNT0'
                    );
                } else {
                    assert(
                        delta.amount1.mag <= callback.calculated_amount_threshold, 'MAX_AMOUNT1'
                    );
                }
            } else {
                // if exact input, the limit is a minimum amount out
                if callback.swap_params.is_token1 {
                    assert(
                        delta.amount0.mag >= callback.calculated_amount_threshold, 'MIN_AMOUNT0'
                    );
                } else {
                    assert(
                        delta.amount1.mag >= callback.calculated_amount_threshold, 'MIN_AMOUNT1'
                    );
                }
            }

            if increasing {
                // if increasing, the amount0 == output
                if delta.amount0.is_non_zero() {
                    core.withdraw(callback.pool_key.token0, callback.recipient, delta.amount0.mag);
                }
                if delta.amount1.is_non_zero() {
                    IERC20Dispatcher { contract_address: callback.pool_key.token1 }
                        .transfer(core.contract_address, delta.amount1.mag.into());
                    assert(
                        core.deposit(callback.pool_key.token1) == delta.amount1.mag, 'PAID_AMOUNT1'
                    );
                }
            } else {
                // if decreasing, the amount0 == input
                if delta.amount0.is_non_zero() {
                    IERC20Dispatcher { contract_address: callback.pool_key.token0 }
                        .transfer(core.contract_address, delta.amount0.mag.into());
                    assert(
                        core.deposit(callback.pool_key.token0) == delta.amount0.mag, 'PAID_AMOUNT0'
                    );
                }
                if delta.amount1.is_non_zero() {
                    core.withdraw(callback.pool_key.token1, callback.recipient, delta.amount1.mag);
                }
            }

            let mut output: Array<felt252> = ArrayTrait::new();
            Serde::serialize(@delta, ref output);
            output
        }
    }


    #[external(v0)]
    impl SimpleSwapperImpl of ISimpleSwapper<ContractState> {
        fn swap(
            ref self: ContractState,
            pool_key: PoolKey,
            swap_params: SwapParameters,
            recipient: ContractAddress,
            calculated_amount_threshold: u128,
        ) -> Delta {
            call_core_with_callback(
                self.core.read(),
                @SwapCallbackData { pool_key, swap_params, recipient, calculated_amount_threshold, }
            )
        }

        fn clear(ref self: ContractState, token: ContractAddress) -> u256 {
            let dispatcher = IERC20Dispatcher { contract_address: token };
            let balance = dispatcher.balanceOf(get_contract_address());
            if (balance.is_non_zero()) {
                dispatcher.transfer(get_caller_address(), balance);
            }
            balance
        }
    }
}
