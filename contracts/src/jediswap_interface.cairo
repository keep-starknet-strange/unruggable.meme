// JediSwap contract interfaces 
// Link: https://github.com/jediswaplabs/JediSwap/tree/31-upgrade-to-cairo-10/src

use starknet::{ClassHash, ContractAddress};

#[starknet::interface]
trait IFactoryC1<T> {
    // view functions
    fn get_pair(self: @T, token0: ContractAddress, token1: ContractAddress) -> ContractAddress;
    fn get_all_pairs(self: @T) -> (u32, Array::<ContractAddress>);
    fn get_num_of_pairs(self: @T) -> u32;
    fn get_fee_to(self: @T) -> ContractAddress;
    fn get_fee_to_setter(self: @T) -> ContractAddress;
    fn get_pair_contract_class_hash(self: @T) -> ClassHash;
    // external functions
    fn create_pair(
        ref self: T, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> ContractAddress;
    fn set_fee_to(ref self: T, new_fee_to: ContractAddress);
    fn set_fee_to_setter(ref self: T, new_fee_to_setter: ContractAddress);
    fn replace_implementation_class(ref self: T, new_implementation_class: ClassHash);
    fn replace_pair_contract_hash(ref self: T, new_pair_contract_class: ClassHash);
}

#[starknet::interface]
trait IRouterC1<T> {
    // view functions
    fn factory(self: @T) -> ContractAddress;
    fn sort_tokens(
        self: @T, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> (ContractAddress, ContractAddress);
    fn quote(self: @T, amountA: u256, reserveA: u256, reserveB: u256) -> u256;
    fn get_amount_out(self: @T, amountIn: u256, reserveIn: u256, reserveOut: u256) -> u256;
    fn get_amount_in(self: @T, amountOut: u256, reserveIn: u256, reserveOut: u256) -> u256;
    fn get_amounts_out(self: @T, amountIn: u256, path: Array::<ContractAddress>) -> Array::<u256>;
    fn get_amounts_in(self: @T, amountOut: u256, path: Array::<ContractAddress>) -> Array::<u256>;
    // external functions
    fn add_liquidity(
        ref self: T,
        tokenA: ContractAddress,
        tokenB: ContractAddress,
        amountADesired: u256,
        amountBDesired: u256,
        amountAMin: u256,
        amountBMin: u256,
        to: ContractAddress,
        deadline: u64
    ) -> (u256, u256, u256);
    fn remove_liquidity(
        ref self: T,
        tokenA: ContractAddress,
        tokenB: ContractAddress,
        liquidity: u256,
        amountAMin: u256,
        amountBMin: u256,
        to: ContractAddress,
        deadline: u64
    ) -> (u256, u256);
    fn swap_exact_tokens_for_tokens(
        ref self: T,
        amountIn: u256,
        amountOutMin: u256,
        path: Array::<ContractAddress>,
        to: ContractAddress,
        deadline: u64
    ) -> Array::<u256>;
    fn swap_tokens_for_exact_tokens(
        ref self: T,
        amountOut: u256,
        amountInMax: u256,
        path: Array::<ContractAddress>,
        to: ContractAddress,
        deadline: u64
    ) -> Array::<u256>;
    fn replace_implementation_class(ref self: T, new_implementation_class: ClassHash);
}

#[starknet::interface]
trait IPairC1<TContractState> {
    // view functions
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn total_supply(self: @TContractState) -> u256;
    fn totalSupply(self: @TContractState) -> u256; //TODO Remove after regenesis?
    fn decimals(self: @TContractState) -> u8;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn balanceOf(
        self: @TContractState, account: ContractAddress
    ) -> u256; //TODO Remove after regenesis?
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn token0(self: @TContractState) -> ContractAddress;
    fn token1(self: @TContractState) -> ContractAddress;
    fn get_reserves(self: @TContractState) -> (u256, u256, u64);
    fn price_0_cumulative_last(self: @TContractState) -> u256;
    fn price_1_cumulative_last(self: @TContractState) -> u256;
    fn klast(self: @TContractState) -> u256;
    // external functions
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn transferFrom(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool; //TODO Remove after regenesis?
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn increase_allowance(
        ref self: TContractState, spender: ContractAddress, added_value: u256
    ) -> bool;
    fn increaseAllowance(
        ref self: TContractState, spender: ContractAddress, added_value: u256
    ) -> bool; //TODO Remove after regenesis?
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    ) -> bool;
    fn decreaseAllowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    ) -> bool; //TODO Remove after regenesis?
    fn mint(ref self: TContractState, to: ContractAddress) -> u256;
    fn burn(ref self: TContractState, to: ContractAddress) -> (u256, u256);
    fn swap(
        ref self: TContractState,
        amount0Out: u256,
        amount1Out: u256,
        to: ContractAddress,
        data: Array::<felt252>
    );
    fn skim(ref self: TContractState, to: ContractAddress);
    fn sync(ref self: TContractState);
    fn replace_implementation_class(ref self: TContractState, new_implementation_class: ClassHash);
}

#[starknet::interface]
trait IERC20<TContractState> {
    // view functions
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    // external functions
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn increase_allowance(
        ref self: TContractState, spender: ContractAddress, added_value: u256
    ) -> bool;
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    ) -> bool;
}
