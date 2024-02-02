use array::ArrayTrait;
use core::option::OptionTrait;
use core::traits::TryInto;
use debug::PrintTrait;
use ekubo::components::clear::{IClearDispatcher, IClearDispatcherTrait};
use ekubo::interfaces::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use ekubo::interfaces::router::{Depth, Delta, RouteNode, TokenAmount};
use ekubo::interfaces::router::{IRouterDispatcher, IRouterDispatcherTrait};
use ekubo::types::bounds::Bounds;
use ekubo::types::i129::i129;
use ekubo::types::keys::PoolKey;
use openzeppelin::token::erc20::interface::{
    IERC20, IERC20Metadata, ERC20ABIDispatcher, ERC20ABIDispatcherTrait
};
use starknet::{get_contract_address, ContractAddress, ClassHash};
use unruggable::errors;
use unruggable::exchanges::ekubo::launcher::{
    IEkuboLauncherDispatcher, IEkuboLauncherDispatcherTrait, EkuboLP
};
use unruggable::token::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait,
};
use unruggable::utils::math::PercentageMath;
use unruggable::utils::sort_tokens;


#[derive(Copy, Drop, Serde)]
struct EkuboLaunchParameters {
    owner: ContractAddress,
    token_address: ContractAddress,
    quote_address: ContractAddress,
    lp_supply: u256,
    pool_params: EkuboPoolParameters
}

#[derive(Drop, Copy, Serde)]
struct EkuboPoolParameters {
    fee: u128,
    tick_spacing: u128,
    // the sign of the starting tick is positive (false) if quote/token < 1 and negative (true) otherwise
    starting_price: i129,
    // The LP providing bound, upper/lower determined by the address of the LPed tokens
    bound: u128,
}

impl EkuboAdapterImpl of unruggable::exchanges::ExchangeAdapter<
    EkuboPoolParameters, (u64, EkuboLP)
> {
    fn create_and_add_liquidity(
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        quote_address: ContractAddress,
        lp_supply: u256,
        additional_parameters: EkuboPoolParameters,
    ) -> (u64, EkuboLP) {
        let ekubo_launch_params = EkuboLaunchParameters {
            owner: starknet::get_caller_address(),
            token_address: token_address,
            quote_address: quote_address,
            lp_supply: lp_supply,
            pool_params: EkuboPoolParameters {
                fee: additional_parameters.fee,
                tick_spacing: additional_parameters.tick_spacing,
                starting_price: additional_parameters.starting_price,
                bound: additional_parameters.bound,
            }
        };
        let ekubo_launchpad = IEkuboLauncherDispatcher { contract_address: exchange_address };
        assert(ekubo_launchpad.contract_address.is_non_zero(), errors::EXCHANGE_ADDRESS_ZERO);

        // Transfer all tokens to the launchpad contract.
        // The team will buyback the tokens from the pool after the LPing operation to earn their initial allocation.
        let memecoin = IUnruggableMemecoinDispatcher { contract_address: token_address, };
        let this = get_contract_address();
        memecoin.transfer(ekubo_launchpad.contract_address, memecoin.balance_of(this));

        // Launch the token, which creates two positions: one concentrated at initial_tick
        // for the team allocation and one on the range [initial_tick, inf] for the initial LP.
        let (id, position) = ekubo_launchpad.launch_token(ekubo_launch_params);

        // Ensure that the LPing operation has not returned more than 0.5% of the provided liquidity to the caller.
        // Otherwise, there was an error in the LP parameters.
        let total_supply = memecoin.total_supply();
        let max_returned_tokens = PercentageMath::percent_mul(total_supply, 50);
        assert(memecoin.balanceOf(this) < max_returned_tokens, 'ekubo has returned tokens');

        // Finally, buy the reserved team tokens from the pool.
        // This requires having transferred the quote tokens to the factory before.
        // As the pool was created with a fixed price for these n% allocated to the team,
        // the required amount should be (%alloc * total_supply) * price.
        let (token0, token1) = sort_tokens(token_address, ekubo_launch_params.quote_address);
        let pool_key = PoolKey {
            token0: token0,
            token1: token1,
            fee: ekubo_launch_params.pool_params.fee,
            tick_spacing: ekubo_launch_params.pool_params.tick_spacing,
            extension: 0.try_into().unwrap(),
        };
        let team_allocation = total_supply - lp_supply;
        buy_tokens_from_pool(
            ekubo_launchpad, pool_key, team_allocation, token_address, quote_address
        );

        assert(memecoin.balanceOf(this) >= team_allocation, 'failed buying team tokens');
        // Distribution to the holders is done in the next step.

        (id, position)
    }
}

/// Buys tokens from a liquidity pool.
///
/// It first determines the square root price limits for the swap based on whether the quote token is token1 or token0 in the pool.
/// It then creates a route node for the swap, transfers the quote tokens to the router contract,
/// and calls the router's swap function with an exact output amount.
/// Finally, it calls the clearer's clear function for both the token to buy and the quote token.
///
/// # Arguments
///
/// * `ekubo_launchpad` - A dispatcher for the Ekubo launchpad contract.
/// * `pool_key` - The key of the liquidity pool.
/// * `amount` - The amount of tokens to buy.
/// * `token_to_buy` - The address of the token to buy.
/// * `quote_address` - The address of the quote token.
///
fn buy_tokens_from_pool(
    ekubo_launchpad: IEkuboLauncherDispatcher,
    pool_key: PoolKey,
    amount: u256,
    token_to_buy: ContractAddress,
    quote_address: ContractAddress,
) {
    let ekubo_router = IRouterDispatcher {
        contract_address: ekubo_launchpad.ekubo_router_address()
    };
    let ekubo_clearer = IClearDispatcher {
        contract_address: ekubo_launchpad.ekubo_router_address()
    };

    let token_to_buy = IUnruggableMemecoinDispatcher { contract_address: token_to_buy };

    let max_sqrt_ratio_limit = 6277100250585753475930931601400621808602321654880405518632;
    let min_sqrt_ratio_limit = 18446748437148339061;

    let is_token1 = pool_key.token1 == quote_address;
    let (sqrt_limit_swap1, sqrt_limit_swap2) = if is_token1 {
        (max_sqrt_ratio_limit, min_sqrt_ratio_limit)
    } else {
        (min_sqrt_ratio_limit, max_sqrt_ratio_limit)
    };

    let route_node = RouteNode {
        pool_key: pool_key, sqrt_ratio_limit: sqrt_limit_swap1, skip_ahead: 0
    };

    let quote_token = IERC20Dispatcher { contract_address: quote_address };
    let this = get_contract_address();
    // Buy tokens from the pool, with an exact output amount.
    let token_amount = TokenAmount {
        token: token_to_buy.contract_address,
        amount: i129 { mag: amount.low, sign: true // negative (true) sign is exact output
         },
    };

    // We transfer quote tokens to the swapper contract, which performs the swap
    // It then sends back the funds to the caller once cleared.
    quote_token.transfer(ekubo_router.contract_address, quote_token.balanceOf(this));
    // Swap and clear the tokens to finalize.
    ekubo_router.swap(route_node, token_amount);
    ekubo_clearer.clear(IERC20Dispatcher { contract_address: token_to_buy.contract_address });
    ekubo_clearer
        .clear_minimum_to_recipient(
            IERC20Dispatcher { contract_address: quote_address }, 0, starknet::get_caller_address()
        );
}
