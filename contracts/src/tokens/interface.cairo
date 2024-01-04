use openzeppelin::token::erc20::interface::{IERC20Metadata, IERC20, IERC20Camel};
use starknet::ContractAddress;
use super::memecoin::LiquidityPosition;
use unruggable::exchanges::SupportedExchanges;

#[starknet::interface]
trait IUnruggableMemecoin<TState> {
    // ************************************
    // * Ownership
    // ************************************
    fn owner(self: @TState) -> ContractAddress;
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TState);

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
    fn is_launched(self: @TState) -> bool;
    fn get_team_allocation(self: @TState) -> u256;
    fn memecoin_factory_address(self: @TState) -> ContractAddress;
    fn lock_manager_address(self: @TState) -> ContractAddress;
    fn set_launched(ref self: TState, liquidity_position: LiquidityPosition);
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
    ///  * bool: whether token has launched
    fn is_launched(self: @TState) -> bool;
    fn get_team_allocation(self: @TState) -> u256;
    fn memecoin_factory_address(self: @TState) -> ContractAddress;
    fn lock_manager_address(self: @TState) -> ContractAddress;
    fn set_launched(ref self: TState, liquidity_position: LiquidityPosition);
}
