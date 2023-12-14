// JediSwap contract interfaces 
// Link: https://github.com/jediswaplabs/JediSwap/tree/31-upgrade-to-cairo-10/src

use starknet::{ClassHash, ContractAddress};

#[starknet::interface]
trait IFactoryC1<TContractState> {
    fn get_pair(
        self: @TContractState, token0: ContractAddress, token1: ContractAddress
    ) -> ContractAddress;
    fn create_pair(
        ref self: TContractState, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> ContractAddress;
}

#[starknet::interface]
trait IRouterC1<T> {
    // view functions
    fn factory(self: @T) -> ContractAddress;
    fn sort_tokens(
        self: @T, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> (ContractAddress, ContractAddress);
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
}

#[starknet::interface]
trait IPair<T> {
    fn get_reserves(self: @T) -> (u256, u256, u64);
    fn mint(ref self: T, to: ContractAddress) -> u256;
    fn totalSupply(self: @T) -> u256;
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
