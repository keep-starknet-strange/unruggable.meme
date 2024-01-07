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
