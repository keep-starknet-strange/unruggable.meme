use core::debug::PrintTrait;
use core::traits::TryInto;
use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait};
use ekubo::types::bounds::Bounds;
use ekubo::types::i129::i129;
use ekubo::types::keys::PoolKey;
use ekubo::interfaces::router::{Depth, Delta, RouteNode, TokenAmount};
use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{
    start_prank, stop_prank, start_spoof, stop_spoof, spy_events, SpyOn, EventSpy, EventAssertions,
    CheatTarget, TxInfoMock
};
use starknet::ContractAddress;
use unruggable::exchanges::SupportedExchanges;
use unruggable::exchanges::ekubo::launcher::{
    IEkuboLauncherDispatcher, IEkuboLauncherDispatcherTrait, EkuboLP
};
use unruggable::exchanges::ekubo_adapter::EkuboPoolParameters;
use unruggable::factory::interface::{IFactoryDispatcher, IFactoryDispatcherTrait};
use unruggable::factory::{Factory};
use unruggable::locker::LockPosition;
use unruggable::locker::interface::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::tests::addresses::{EKUBO_CORE};
use unruggable::tests::fork_tests::utils::{
    deploy_memecoin_through_factory_with_owner, sort_tokens, EKUBO_LAUNCHER_ADDRESS,
    EKUBO_ROUTER_ADDRESS, deploy_token0_with_owner, deploy_eth_with_owner
};
use unruggable::tests::unit_tests::utils::{
    OWNER, DEFAULT_MIN_LOCKTIME, pow_256, LOCK_MANAGER_ADDRESS, MEMEFACTORY_ADDRESS, RECIPIENT,
    ALICE, DefaultTxInfoMock, TRANSFER_RESTRICTION_DELAY, MAX_PERCENTAGE_BUY_LAUNCH
};
use unruggable::token::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};
use unruggable::token::memecoin::LiquidityType;
use unruggable::utils::math::PercentageMath;

//! copy of ekubo's router interface, added the `clear` entrypoint (which is missing from interface)
#[starknet::interface]
trait IRouter<TContractState> {
    // Does a single swap against a single node using tokens held by this contract, and receives the output to this contract
    fn swap(ref self: TContractState, node: RouteNode, token_amount: TokenAmount) -> Delta;

    // Does a multihop swap, where the output/input of each hop is passed as input/output of the next swap
    // Note to do exact output swaps, the route must be given in reverse
    fn multihop_swap(
        ref self: TContractState, route: Array<RouteNode>, token_amount: TokenAmount
    ) -> Array<Delta>;

    // Quote the given token amount against the route in the swap
    fn quote(
        ref self: TContractState, route: Array<RouteNode>, token_amount: TokenAmount
    ) -> Array<Delta>;

    // Returns the delta for swapping a pool to the given price
    fn get_delta_to_sqrt_ratio(self: @TContractState, pool_key: PoolKey, sqrt_ratio: u256) -> Delta;

    // Returns the amount available for purchase for swapping +/- the given percent, expressed as a 0.128 number
    // Note this is a square root of the percent
    // e.g. if you want to get the 2% market depth, you'd pass FLOOR((sqrt(1.02) - 1) * 2**128) = 3385977594616997568912048723923598803
    fn get_market_depth(self: @TContractState, pool_key: PoolKey, sqrt_percent: u128) -> Depth;

    fn clear(ref self: TContractState, token: ContractAddress);
}


fn launch_memecoin_on_ekubo(
    quote_address: ContractAddress, fee: u128, tick_spacing: u128, starting_tick: i129, bound: u128
) -> (ContractAddress, u64, EkuboLP) {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };

    let (id, position) = factory
        .launch_on_ekubo(
            memecoin_address,
            TRANSFER_RESTRICTION_DELAY,
            MAX_PERCENTAGE_BUY_LAUNCH,
            quote_address,
            EkuboPoolParameters { fee, tick_spacing, starting_tick, bound }
        );

    (memecoin_address, id, position)
}

fn swap_tokens_on_ekubo(
    token_in_address: ContractAddress,
    amount_in: u256,
    is_token1: bool,
    price_above_1: bool,
    token_out_address: ContractAddress,
    owner: ContractAddress,
    pool_key: PoolKey
) {
    let token_in = ERC20ABIDispatcher { contract_address: token_in_address };
    let token_out = ERC20ABIDispatcher { contract_address: token_out_address };

    let max_sqrt_ratio_limit = 6277100250585753475930931601400621808602321654880405518632;
    let min_sqrt_ratio_limit = 18446748437148339061;

    let (sqrt_limit_swap1, sqrt_limit_swap2) = if is_token1 {
        (max_sqrt_ratio_limit, min_sqrt_ratio_limit)
    } else {
        (min_sqrt_ratio_limit, max_sqrt_ratio_limit)
    };

    // First swap:
    // We swap quote (token1) for MEME (token0)
    // The initial price of the pool is 0.01quote/MEME = 100MEME/quote.
    // so the received amounts should be around 100x the amount of quote sent
    // with a 5% margin of error for the price impact.
    // since the pool price is expressend in quote/MEME, the price should move upwards (more quote for 1 meme)
    let router_address = EKUBO_ROUTER_ADDRESS();
    let ekubo_router = IRouterDispatcher { contract_address: router_address };
    let first_amount_in = amount_in;

    let mut tx_info: TxInfoMock = Default::default();
    tx_info.transaction_hash = Option::Some(123);
    start_spoof(CheatTarget::One(token_in.contract_address), tx_info);

    // We transfer tokens to the swapper contract, which performs the swap
    // This is required the way the swapper contract is coded.
    // It then sends back the funds to the caller
    start_prank(CheatTarget::One(token_in.contract_address), owner);
    token_in.transfer(router_address, first_amount_in);
    stop_prank(CheatTarget::One(token_in.contract_address));

    stop_spoof(CheatTarget::One(token_in.contract_address));

    // If MEME/quote > 1 and we swap token1 for token0,
    // OR if MEME/quote < 1 and we swap token0 for token1,
    // we expect to receive 0.01x the amount of quote sent with a 5% margin of error
    let expected_output = if price_above_1 {
        PercentageMath::percent_mul(first_amount_in, 95)
    } else {
        PercentageMath::percent_mul(100 * first_amount_in, 9500)
    };

    let route_node = RouteNode {
        pool_key: pool_key, sqrt_ratio_limit: sqrt_limit_swap1, skip_ahead: 0
    };

    let token_amount = TokenAmount {
        token: token_in.contract_address,
        amount: i129 { mag: first_amount_in.low, sign: false // positive sign is exact input
         },
    };
    ekubo_router.swap(route_node, token_amount);
    ekubo_router.clear(token_out.contract_address);

    // Second swap:

    // We swap MEME (token0) for quote (token1)
    // the expected amount should be the initial amount,
    // minus the fees of the pool.
    let second_amount_in = token_out.balance_of(owner);
    let second_expected_output = PercentageMath::percent_mul(first_amount_in, 9940);
    let balance_token_in_before = token_in.balance_of(owner);

    let mut tx_info: TxInfoMock = Default::default();
    tx_info.transaction_hash = Option::Some(456);
    start_spoof(CheatTarget::One(token_out.contract_address), tx_info);

    start_prank(CheatTarget::One(token_out.contract_address), owner);
    token_out.transfer(router_address, second_amount_in);
    stop_prank(CheatTarget::One(token_out.contract_address));

    stop_spoof(CheatTarget::One(token_out.contract_address));

    let route_node = RouteNode {
        pool_key: pool_key, sqrt_ratio_limit: sqrt_limit_swap2, skip_ahead: 0
    };

    let token_amount = TokenAmount {
        token: token_out.contract_address,
        amount: i129 { mag: second_amount_in.low, sign: false // exact input
         },
    };

    ekubo_router.swap(route_node, token_amount);
    ekubo_router.clear(token_in.contract_address);

    let token_in_received = token_in.balance_of(owner) - balance_token_in_before;
    assert(token_in_received >= second_expected_output, 'swap output too low');
}

#[test]
#[fork("Mainnet")]
fn test_locked_liquidity_ekubo() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let starting_tick = i129 { sign: true, mag: 4600158 };
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    );
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };

    let (locker_address, locked_type) = factory.locked_liquidity(memecoin_address).unwrap();
    assert(locker_address == EKUBO_LAUNCHER_ADDRESS(), 'wrong locker address');
    match locked_type {
        LiquidityType::ERC20(_) => panic_with_felt252('wrong liquidity type'),
        LiquidityType::NFT(id) => ()
    }
}

#[test]
#[fork("Mainnet")]
fn test_launch_meme() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let starting_tick = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
    let mut spy = spy_events(SpyOn::One(MEMEFACTORY_ADDRESS()));
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    ); // 0.3/0.6%
    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

    let (token0, token1) = sort_tokens(quote_address, memecoin_address);
    let pool_key = PoolKey {
        token0: position.pool_key.token0,
        token1: position.pool_key.token1,
        fee: position.pool_key.fee.try_into().unwrap(),
        tick_spacing: position.pool_key.tick_spacing.try_into().unwrap(),
        extension: position.pool_key.extension
    };

    let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    let liquidity = core.get_pool_liquidity(pool_key);
    let price = core.get_pool_price(pool_key);
    let reserve_memecoin = memecoin.balance_of(core.contract_address);
    let reserve_quote = ERC20ABIDispatcher { contract_address: quote_address }
        .balance_of(core.contract_address);
    assert(reserve_quote == 0, 'reserve quote not 0');

    // Verify that the reserve of memecoin is within 0.5% of the (total supply minus the team allocation)
    // When providing liquidity, if the liquidity provided doesn't exactly match the repartition between
    // bounds, a very small amount is returned.
    let team_alloc = memecoin.get_team_allocation();
    let expected_reserve_lower_bound = PercentageMath::percent_mul(
        memecoin.totalSupply() - team_alloc, 9950,
    );
    assert(reserve_memecoin > expected_reserve_lower_bound, 'reserves holds too few token');

    // Check LP position tracked
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };
    let lp_positions = ekubo_launcher.launched_tokens(owner);
    assert(lp_positions.len() == 1, 'should have 1 LP position');
    let lp_details = ekubo_launcher.liquidity_position_details(*lp_positions[0]);
    assert(lp_details.owner == owner, 'wrong owner');
    assert(lp_details.quote_address == quote_address, 'wrong quote');
    assert(lp_details.pool_key == pool_key, 'wrong pool key');
    assert(
        lp_details
            .bounds == Bounds { lower: starting_tick, upper: i129 { sign: false, mag: 88719042 } },
        'wrong bounds '
    );

    // Check events
    spy
        .assert_emitted(
            @array![
                (
                    MEMEFACTORY_ADDRESS(),
                    Factory::Event::MemecoinLaunched(
                        Factory::MemecoinLaunched {
                            memecoin_address, quote_token: quote_address, exchange_name: 'Ekubo'
                        }
                    )
                )
            ]
        );
}

#[test]
#[fork("Mainnet")]
fn test_transfer_ekuboLP_position() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let starting_tick = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    );

    // Execute the transfer of position
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };
    ekubo_launcher.transfer_position_ownership(id, ALICE());

    // Check that LP transfer to Alice is successful
    assert(
        ekubo_launcher.launched_tokens(ALICE()).len() == 1
            && ekubo_launcher.launched_tokens(owner).len() == 0,
        'transfer failed'
    );

    assert(
        ekubo_launcher.liquidity_position_details(id).owner == ALICE(),
        'launcher storage not updated'
    );
}

#[test]
#[fork("Mainnet")]
fn test_swap_token0_price_below_1() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let starting_tick = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    );
    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };
    let quote = ERC20ABIDispatcher { contract_address: quote_address };
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };

    let (token0, token1) = sort_tokens(quote_address, memecoin_address);
    let pool_key = PoolKey {
        token0: position.pool_key.token0,
        token1: position.pool_key.token1,
        fee: position.pool_key.fee.try_into().unwrap(),
        tick_spacing: position.pool_key.tick_spacing.try_into().unwrap(),
        extension: position.pool_key.extension
    };

    // Check that swaps work correctly
    let amount_in = MAX_PERCENTAGE_BUY_LAUNCH.into() * pow_256(10, 14);
    swap_tokens_on_ekubo(
        token_in_address: quote_address,
        :amount_in,
        is_token1: true,
        price_above_1: false,
        token_out_address: memecoin_address,
        owner: owner,
        pool_key: pool_key
    );

    // Change tx hash to avoid multicall detection
    let mut tx_info: TxInfoMock = Default::default();
    tx_info.transaction_hash = Option::Some(1);
    start_spoof(CheatTarget::One(memecoin_address), tx_info);

    // Test that the owner of the LP can withdraw fees from the launcher
    let recipient = RECIPIENT();
    ekubo_launcher.withdraw_fees(id, recipient);
    let balance_of_memecoin = memecoin.balance_of(recipient);
    let balance_of_quote = quote.balance_of(recipient);
    assert(balance_of_memecoin == 0, 'memecoin shouldnt collect fees');
    assert(
        balance_of_quote == PercentageMath::percent_mul(amount_in, 0030),
        'should collect 0.3% of eth'
    );
}

#[test]
#[fork("Mainnet")]
fn test_launch_meme_token1_price_below_1() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_token0_with_owner(owner);
    let starting_tick = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    );
    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };
    let quote = ERC20ABIDispatcher { contract_address: quote_address };
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };

    // Test that swaps work correctly

    let (token0_address, token1_address) = sort_tokens(quote_address, memecoin_address);
    assert(token0_address == quote_address, 'token0 not quote');

    let pool_key = PoolKey {
        token0: position.pool_key.token0,
        token1: position.pool_key.token1,
        fee: position.pool_key.fee.try_into().unwrap(),
        tick_spacing: position.pool_key.tick_spacing.try_into().unwrap(),
        extension: position.pool_key.extension
    };

    let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    let liquidity = core.get_pool_liquidity(pool_key);
    let price = core.get_pool_price(pool_key);
    let reserve_memecoin = memecoin.balance_of(core.contract_address);
    let reserve_quote = ERC20ABIDispatcher { contract_address: quote_address }
        .balance_of(core.contract_address);
    assert(reserve_quote == 0, 'reserve quote not 0');

    // Verify that the reserve of memecoin is within 0.5% of the (total supply minus the team allocation)
    let team_alloc = memecoin.get_team_allocation();
    let expected_reserve_lower_bound = PercentageMath::percent_mul(
        memecoin.totalSupply() - team_alloc, 9950,
    );
    assert(reserve_memecoin > expected_reserve_lower_bound, 'reserves holds too few token');

    let amount_in = MAX_PERCENTAGE_BUY_LAUNCH.into() * pow_256(10, 14);
    swap_tokens_on_ekubo(
        token_in_address: quote_address,
        :amount_in,
        is_token1: false,
        price_above_1: false,
        token_out_address: memecoin_address,
        owner: owner,
        pool_key: pool_key
    );

    // Change tx hash to avoid multicall detection
    let mut tx_info: TxInfoMock = Default::default();
    tx_info.transaction_hash = Option::Some(1);
    start_spoof(CheatTarget::One(memecoin_address), tx_info);

    // Test that the owner of the LP can withdraw fees from the launcher
    let recipient = RECIPIENT();
    ekubo_launcher.withdraw_fees(id, recipient);
    let balance_of_memecoin = memecoin.balance_of(recipient);
    let balance_of_quote = quote.balance_of(recipient);
    assert(balance_of_memecoin == 0, 'memecoin shouldnt collect fees');
    assert(
        balance_of_quote == PercentageMath::percent_mul(amount_in, 0030),
        'should collect 0.3% of eth'
    );
}

#[test]
#[fork("Mainnet")]
fn test_launch_meme_token0_price_above_1() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let starting_tick = i129 { sign: false, mag: 4600158 }; // 100quote/MEME
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    );
    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };
    let quote = ERC20ABIDispatcher { contract_address: quote_address };
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };

    // Test that swaps work correctly

    let (token0, token1) = sort_tokens(quote.contract_address, memecoin_address);

    let pool_key = PoolKey {
        token0: position.pool_key.token0,
        token1: position.pool_key.token1,
        fee: position.pool_key.fee.try_into().unwrap(),
        tick_spacing: position.pool_key.tick_spacing.try_into().unwrap(),
        extension: position.pool_key.extension
    };

    let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    let liquidity = core.get_pool_liquidity(pool_key);
    let price = core.get_pool_price(pool_key);
    let reserve_memecoin = memecoin.balance_of(core.contract_address);
    let reserve_quote = ERC20ABIDispatcher { contract_address: quote_address }
        .balance_of(core.contract_address);
    assert(reserve_quote == 0, 'reserve quote not 0');

    // Verify that the reserve of memecoin is within 0.5% of the (total supply minus the team allocation)
    let team_alloc = memecoin.get_team_allocation();
    let expected_reserve_lower_bound = PercentageMath::percent_mul(
        memecoin.totalSupply() - team_alloc, 9950,
    );
    assert(reserve_memecoin > expected_reserve_lower_bound, 'reserves holds too few token');

    // Test that swaps work correctly
    let amount_in = MAX_PERCENTAGE_BUY_LAUNCH.into() * pow_256(10, 14);
    swap_tokens_on_ekubo(
        token_in_address: quote_address,
        :amount_in,
        is_token1: true,
        price_above_1: true,
        token_out_address: memecoin_address,
        owner: owner,
        pool_key: pool_key
    );

    // Change tx hash to avoid multicall detection
    let mut tx_info: TxInfoMock = Default::default();
    tx_info.transaction_hash = Option::Some(1);
    start_spoof(CheatTarget::One(memecoin_address), tx_info);

    // Test that the owner of the LP can withdraw fees from the launcher
    let recipient = RECIPIENT();
    ekubo_launcher.withdraw_fees(id, recipient);
    let balance_of_memecoin = memecoin.balance_of(recipient);
    let balance_of_quote = quote.balance_of(recipient);
    assert(balance_of_memecoin == 0, 'memecoin shouldnt collect fees');
    assert(
        balance_of_quote == PercentageMath::percent_mul(amount_in, 0030),
        'should collect 0.3% of eth'
    );
}

#[test]
#[fork("Mainnet")]
fn test_launch_meme_token1_price_above_1() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_token0_with_owner(owner);
    let starting_tick = i129 { sign: false, mag: 4600158 }; // 100quote/MEME
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    );
    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };
    let quote = ERC20ABIDispatcher { contract_address: quote_address };
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };

    // Test that swaps work correctly

    let (token0_address, token1_address) = sort_tokens(quote.contract_address, memecoin_address);
    assert(token0_address == quote.contract_address, 'token0 not quote');

    let pool_key = PoolKey {
        token0: position.pool_key.token0,
        token1: position.pool_key.token1,
        fee: position.pool_key.fee.try_into().unwrap(),
        tick_spacing: position.pool_key.tick_spacing.try_into().unwrap(),
        extension: position.pool_key.extension
    };

    let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    let liquidity = core.get_pool_liquidity(pool_key);
    let price = core.get_pool_price(pool_key);
    let reserve_memecoin = memecoin.balance_of(core.contract_address);
    let reserve_token0 = ERC20ABIDispatcher { contract_address: quote_address }
        .balance_of(core.contract_address);
    assert(reserve_token0 == 0, 'reserve quote not 0');

    // Verify that the reserve of memecoin is within 0.5% of the (total supply minus the team allocation)
    let team_alloc = memecoin.get_team_allocation();
    let expected_reserve_lower_bound = PercentageMath::percent_mul(
        memecoin.totalSupply() - team_alloc, 9950,
    );
    assert(reserve_memecoin > expected_reserve_lower_bound, 'reserves holds too few token');

    // Check that swaps work correctly
    let amount_in = MAX_PERCENTAGE_BUY_LAUNCH.into() * pow_256(10, 14);
    swap_tokens_on_ekubo(
        token_in_address: quote_address,
        :amount_in,
        is_token1: false,
        price_above_1: true,
        token_out_address: memecoin_address,
        owner: owner,
        pool_key: pool_key
    );

    // Change tx hash to avoid multicall detection
    let mut tx_info: TxInfoMock = Default::default();
    tx_info.transaction_hash = Option::Some(1);
    start_spoof(CheatTarget::One(memecoin_address), tx_info);

    // Test that the owner of the LP can withdraw fees from the launcher
    let recipient = RECIPIENT();
    ekubo_launcher.withdraw_fees(id, recipient);
    let balance_of_memecoin = memecoin.balance_of(recipient);
    let balance_of_quote = quote.balance_of(recipient);
    assert(balance_of_memecoin == 0, 'memecoin shouldnt collect fees');
    assert(
        balance_of_quote == PercentageMath::percent_mul(amount_in, 0030),
        'should collect 0.3% of eth'
    );
}

#[test]
#[fork("Mainnet")]
fn test_launch_meme_with_pool_1percent() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let starting_tick = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0x28f5c28f5c28f600000000000000000, 5982, starting_tick, 88719042
    );
    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

    let (token0, token1) = sort_tokens(quote_address, memecoin_address);
    let pool_key = PoolKey {
        token0: position.pool_key.token0,
        token1: position.pool_key.token1,
        fee: position.pool_key.fee.try_into().unwrap(),
        tick_spacing: position.pool_key.tick_spacing.try_into().unwrap(),
        extension: position.pool_key.extension
    };
    let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    let liquidity = core.get_pool_liquidity(pool_key);
    let price = core.get_pool_price(pool_key);
    let reserve_memecoin = memecoin.balance_of(core.contract_address);
    let reserve_token0 = ERC20ABIDispatcher { contract_address: quote_address }
        .balance_of(core.contract_address);
    assert(reserve_token0 == 0, 'reserve quote not 0');

    // Verify that the reserve of memecoin is within 0.5% of the (total supply minus the team allocation)
    let team_alloc = memecoin.get_team_allocation();
    let expected_reserve_lower_bound = PercentageMath::percent_mul(
        memecoin.totalSupply() - team_alloc, 9950,
    );
    assert(reserve_memecoin > expected_reserve_lower_bound, 'reserves holds too few token');
}

#[test]
#[fork("Mainnet")]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_not_owner_cant_withdraw_fees() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let starting_tick = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    );
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };

    let recipient = RECIPIENT();
    let caller = 'not owner'.try_into().unwrap();
    start_prank(CheatTarget::One(ekubo_launcher.contract_address), caller);
    ekubo_launcher.withdraw_fees(id, recipient);
    stop_prank(CheatTarget::One(ekubo_launcher.contract_address));
}

#[test]
#[fork("Mainnet")]
#[should_panic(expected: ('Starting tick cannot be 0',))]
fn test_cant_launch_with_0_starting_tick() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let starting_tick = i129 { sign: true, mag: 0 }; // 0.0ETH/MEME
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    );
}

#[test]
#[fork("Mainnet")]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_cant_launch_twice() {
    let owner = snforge_std::test_address();
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let starting_tick = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
    let (memecoin_address, id, position) = launch_memecoin_on_ekubo(
        quote_address, 0xc49ba5e353f7d00000000000000000, 5982, starting_tick, 88719042
    );

    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let ekubo_launcher = IEkuboLauncherDispatcher { contract_address: EKUBO_LAUNCHER_ADDRESS() };
    start_prank(CheatTarget::One(factory.contract_address), owner);
    // This will fail as the ownership of the memecoin has been renounced.
    let (id, position) = factory
        .launch_on_ekubo(
            memecoin_address,
            TRANSFER_RESTRICTION_DELAY,
            MAX_PERCENTAGE_BUY_LAUNCH,
            quote_address,
            EkuboPoolParameters {
                fee: 0xc49ba5e353f7d00000000000000000,
                tick_spacing: 5982,
                starting_tick,
                bound: 88719042
            }
        );
}
