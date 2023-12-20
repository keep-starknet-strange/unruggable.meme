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
    fn token0(self: @T) -> ContractAddress;
    fn token1(self: @T) -> ContractAddress;
    fn get_reserves(self: @T) -> (u256, u256, u64);
    fn mint(ref self: T, to: ContractAddress) -> u256;
    fn totalSupply(self: @T) -> u256;
}
