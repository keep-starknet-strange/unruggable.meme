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
    fn launch_memecoin(
        ref self: TState,
        exchange: SupportedExchanges,
        counterparty_token_address: ContractAddress,
        lp_unlock_time: u64,
        additional_launch_parameters: Span<felt252>
    ) -> LiquidityPosition;
    fn get_team_allocation(self: @TState) -> u256;
    fn memecoin_factory_address(self: @TState) -> ContractAddress;
    fn lock_manager_address(self: @TState) -> ContractAddress;
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
    fn is_launched(self: @TState) -> bool;

    /// Launches Memecoin by creating a liquidity pool with the specified counterparty token using the Exchangev2 protocol.
    ///
    /// The owner must send tokens of the chosen counterparty (e.g., USDC) to launch Memecoin.
    ///
    /// # Arguments
    /// * `exchange`: SupportedExchanges to create a pair and send liquidity.
    /// * `liquidity_memecoin_amount`: The amount of Memecoin tokens to be provided as liquidity.
    /// * `liquidity_counterparty_token`: The amount of counterparty tokens to be provided as liquidity.
    /// * `deadline`: The deadline beyond which the operation will revert.
    ///
    /// # Panics
    /// This method will panic if:
    /// * The caller is not the owner of the contract.
    /// * Insufficient Memecoin funds are available for liquidity.
    /// * Insufficient counterparty token funds are available for liquidity.
    ///
    /// # Returns
    /// * `ContractAddress` - The contract address of the created liquidity pool.
    fn launch_memecoin(
        ref self: TState,
        exchange: SupportedExchanges,
        counterparty_token_address: ContractAddress,
        lp_unlock_time: u64,
        additional_launch_parameters: Span<felt252>
    ) -> LiquidityPosition;
    fn get_team_allocation(self: @TState) -> u256;
    fn memecoin_factory_address(self: @TState) -> ContractAddress;
    fn lock_manager_address(self: @TState) -> ContractAddress;
}
