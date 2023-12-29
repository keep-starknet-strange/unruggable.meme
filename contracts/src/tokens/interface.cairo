use openzeppelin::token::erc20::interface::{IERC20Metadata, IERC20, IERC20Camel};
use starknet::ContractAddress;
use unruggable::amm::amm::AMMV2;

#[starknet::interface]
trait IUnruggableMemecoin<TState> {
    // ************************************
    // * Metadata
    // ************************************
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn decimals(self: @TState) -> u8;

    // ************************************
    // * snake_case
    // ************************************
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;

    // ************************************
    // * camelCase
    // ************************************
    fn totalSupply(self: @TState) -> u256;
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn transferFrom(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;

    // ************************************
    // * Additional functions
    // ************************************
    /// Checks whether token has launched
    ///
    /// # Returns 
    ///     bool: whether token has launched
    fn launched(self: @TState) -> bool;
    fn launch_memecoin(
        ref self: TState,
        amm_v2: AMMV2,
        counterparty_token_address: ContractAddress,
        deadline: u64
    ) -> ContractAddress;
    fn get_team_allocation(self: @TState) -> u256;
}

#[starknet::interface]
trait IUnruggableMemecoinCamel<TState> {
    fn totalSupply(self: @TState) -> u256;
    fn balanceOf(self: @TState, account: ContractAddress) -> u256;
    fn transferFrom(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
}

#[starknet::interface]
trait IUnruggableMemecoinSnake<TState> {
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;
}

#[starknet::interface]
trait IUnruggableAdditional<TState> {
    /// Checks whether token has launched
    ///
    /// # Returns 
    ///     bool: whether token has launched
    fn launched(self: @TState) -> bool;
    fn launch_memecoin(
        ref self: TState, amm_v2: AMMV2, counterparty_token_address: ContractAddress, deadline: u64
    ) -> ContractAddress;
    fn get_team_allocation(self: @TState) -> u256;
}
