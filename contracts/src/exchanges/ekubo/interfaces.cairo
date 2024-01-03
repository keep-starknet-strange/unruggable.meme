use ekubo::types::bounds::{Bounds};
use ekubo::types::i129::{i129};
use ekubo::types::keys::{PoolKey};
use ekubo::types::pool_price::{PoolPrice};
use openzeppelin::token::erc20::interface::IERC20Dispatcher;
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq)]
struct GetTokenInfoResult {
    pool_price: PoolPrice,
    liquidity: u128,
    amount0: u128,
    amount1: u128,
    fees0: u128,
    fees1: u128,
}

#[derive(Copy, Drop, Serde)]
struct GetTokenInfoRequest {
    id: u64,
    pool_key: PoolKey,
    bounds: Bounds
}


#[starknet::interface]
trait IOwnedNFT<TStorage> {
    // Create a new token, only callable by the controller
    fn mint(ref self: TStorage, owner: ContractAddress) -> u64;

    // Burn the token with the given ID
    fn burn(ref self: TStorage, id: u64);

    // Returns whether the account is authorized to act on the given token ID
    fn is_account_authorized(self: @TStorage, id: u64, account: ContractAddress) -> bool;

    // Returns the next token ID,
    // i.e. the ID of the token that will be minted on the next call to mint from the controller
    fn get_next_token_id(self: @TStorage) -> u64;
}

#[starknet::interface]
trait ITokenRegistry<ContractState> {
    fn register_token(ref self: ContractState, token: IERC20Dispatcher);
}

#[starknet::interface]
trait IPositions<TStorage> {
    // Returns the address of the NFT contract that represents ownership of a position
    fn get_nft_address(self: @TStorage) -> ContractAddress;

    // Returns the principal and fee amount for a set of positions
    fn get_tokens_info(
        self: @TStorage, params: Array<GetTokenInfoRequest>
    ) -> Array<GetTokenInfoResult>;

    // Return the principal and fee amounts owed to a position
    fn get_token_info(
        self: @TStorage, id: u64, pool_key: PoolKey, bounds: Bounds
    ) -> GetTokenInfoResult;

    // Create a new NFT that represents liquidity in a pool. Returns the newly minted token ID
    fn mint(ref self: TStorage, pool_key: PoolKey, bounds: Bounds) -> u64;

    // Same as above but includes a referrer in the emitted event
    fn mint_with_referrer(
        ref self: TStorage, pool_key: PoolKey, bounds: Bounds, referrer: ContractAddress
    ) -> u64;

    // Delete the NFT. All liquidity controlled by the NFT (not withdrawn) is irrevocably locked.
    // Must be called by an operator, approved address or the owner.
    fn unsafe_burn(ref self: TStorage, id: u64);

    // Deposit in the most recently created token ID. Must be called by an operator, approved address or the owner
    fn deposit_last(
        ref self: TStorage, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> u128;

    // Deposit in a specific token ID. Must be called by an operator, approved address or the owner
    fn deposit(
        ref self: TStorage, id: u64, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> u128;

    // Mint and deposit in a single call
    fn mint_and_deposit(
        ref self: TStorage, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> (u64, u128);

    // Same as above with a referrer
    fn mint_and_deposit_with_referrer(
        ref self: TStorage,
        pool_key: PoolKey,
        bounds: Bounds,
        min_liquidity: u128,
        referrer: ContractAddress
    ) -> (u64, u128);

    // Mint and deposit in a single call, and also clear the tokens
    fn mint_and_deposit_and_clear_both(
        ref self: TStorage, pool_key: PoolKey, bounds: Bounds, min_liquidity: u128
    ) -> (u64, u128, u256, u256);

    // Withdraw liquidity from a specific token ID. Must be called by an operator, approved address or the owner
    fn withdraw(
        ref self: TStorage,
        id: u64,
        pool_key: PoolKey,
        bounds: Bounds,
        liquidity: u128,
        min_token0: u128,
        min_token1: u128,
        collect_fees: bool
    ) -> (u128, u128);

    fn clear(ref self: TStorage, token: ContractAddress) -> u256;
}
