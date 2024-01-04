use core::traits::TryInto;
use debug::PrintTrait;
use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait};
use ekubo::types::i129::i129;
use ekubo::types::keys::PoolKey;
use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{start_prank, stop_prank, CheatTarget};
use unruggable::exchanges::SupportedExchanges;
use unruggable::exchanges::ekubo::launcher::{
    IEkuboLauncherDispatcher, IEkuboLauncherDispatcherTrait
};
use unruggable::locker::LockPosition;
use unruggable::locker::interface::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::mocks::ekubo::swapper::{
    SwapParameters, ISimpleSwapperDispatcher, ISimpleSwapperDispatcherTrait
};
use unruggable::tests::addresses::{ETH_ADDRESS, EKUBO_CORE, TOKEN0_ADDRESS};
use unruggable::tests::fork_tests::utils::{
    deploy_memecoin_through_factory_with_owner, sort_tokens, EKUBO_LAUNCHER_ADDRESS,
    EKUBO_SWAPPER_ADDRESS, deploy_ekubo_swapper, deploy_token0_with_owner
};
use unruggable::tests::unit_tests::utils::{
    OWNER, DEFAULT_MIN_LOCKTIME, pow_256, LOCK_MANAGER_ADDRESS
};
use unruggable::tokens::interface::{IUnruggableMemecoinDispatcherTrait};
use unruggable::tokens::memecoin::LiquidityPosition;
use unruggable::utils::math::PercentageMath;

#[test]
#[fork("Mainnet")]
fn test_ekubo_launch_meme_token0_and_swap() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };
    let launchpad_address = EKUBO_LAUNCHER_ADDRESS();
    let ekubo_launchpad = IEkuboLauncherDispatcher { contract_address: launchpad_address };

    let unlock_time = starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME;

    // 0.3% fee, 0.6% tick spacing, starting tick is a price of 100 MEME / ETH
    // the starting tick should be computed base on wanted initial price liquidity
    // initial price set at 100MEME/ETH -> 0.01ETH/MEME
    // exact tick = math.log(initial_price,1.000001)
    // initial_tick = (exact_tick // tick_spacing)*tick_spacing
    let (fee, tick_spacing, starting_tick, bound) = (
        0xc49ba5e353f7d00000000000000000, 5982, 4600158, 88719042
    );
    let liquidity_position = memecoin
        .launch_memecoin(
            SupportedExchanges::Ekubo,
            ETH_ADDRESS(),
            unlock_time,
            array![fee, tick_spacing, starting_tick, bound].span()
        );
    let pair_address = match liquidity_position {
        LiquidityPosition::ERC20(_) => panic_with_felt252('Expected NFT position'),
        LiquidityPosition::NFT(id) => id,
    };

    // Test that swaps work correctly

    let (token0, token1) = sort_tokens(eth.contract_address, memecoin_address);
    // hardcoded
    let pool_key = PoolKey {
        token0: token0,
        token1: token1,
        fee: fee.try_into().unwrap(),
        tick_spacing: tick_spacing.try_into().unwrap(),
        extension: 0.try_into().unwrap(),
    };

    let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    let liquidity = core.get_pool_liquidity(pool_key);
    let price = core.get_pool_price(pool_key);
    let reserve_memecoin = core.get_reserves(memecoin_address);
    let reserve_fake_eth = core.get_reserves(ETH_ADDRESS());
    assert(reserve_fake_eth == 0, 'reserve counterparty not 0');

    // Verify that the reserve of memecoin is within 0.5% of the (total supply minus the team allocation)
    let team_alloc = memecoin.get_team_allocation();
    let expected_reserve_lower_bound = PercentageMath::percent_mul(
        memecoin.totalSupply() - team_alloc, 9950,
    );
    assert(reserve_memecoin > expected_reserve_lower_bound, 'reserves holds too few token');

    // Check that swaps work correctly

    // First swap:

    // We swap ETH (token1) for MEME (token0)
    // The initial price of the pool is ~100MEME/ETH
    // so the received amounts should be around 100x the amount of ETH sent
    // with a 5% margin of error for the price impact.
    let swapper_address = deploy_ekubo_swapper();
    let ekubo_swapper = ISimpleSwapperDispatcher { contract_address: swapper_address };
    let first_amount_in = 2 * pow_256(10, 16); // The initial price was fixed
    let swap_params = SwapParameters {
        amount: i129 { mag: first_amount_in.low, sign: false // positive sign is exact input
         },
        is_token1: true,
        sqrt_ratio_limit: 3228201981189909664284139725369263521792, // 90 meme /eth
        skip_ahead: 0,
    };

    // We transfer tokens to the swapper contract, which performs the swap
    // This is required the way the swapper contract is coded.
    // It then sends back the funds to the caller
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.transfer(swapper_address, first_amount_in);
    stop_prank(CheatTarget::One(eth.contract_address));

    // We expect to receive 100x the amount of ETH sent with a 5% margin of error
    let expected_output = PercentageMath::percent_mul(100 * first_amount_in, 9500);
    ekubo_swapper
        .swap(
            pool_key: pool_key,
            swap_params: swap_params,
            recipient: owner,
            calculated_amount_threshold: expected_output
                .low, // threshold is min amount of received tokens
        );

    assert(memecoin.balance_of(owner) >= expected_output, 'swap output too low');
    // Second swap:

    // We swap MEME (token0) for ETH (token1)
    // The initial price of the pool is ~100MEME/ETH
    // so the received amounts should be around 1/100 of the amount of MEME sent
    // the only difference is that the expect amount should be the initial amount,
    // minus the fees of the pool.

    let second_amount_in = memecoin.balance_of(owner);
    let swap_params = SwapParameters {
        amount: i129 { mag: second_amount_in.low, sign: false // exact input
         },
        is_token1: false,
        sqrt_ratio_limit: 18446748437148339061, // 110 meme / eth
        skip_ahead: 0,
    };
    let second_expected_output = PercentageMath::percent_mul(first_amount_in, 9940);
    let balance_eth_before = eth.balance_of(owner);

    start_prank(CheatTarget::One(memecoin_address), owner);
    memecoin.transfer(swapper_address, second_amount_in);
    stop_prank(CheatTarget::One(memecoin_address));

    ekubo_swapper
        .swap(
            pool_key: pool_key,
            swap_params: swap_params,
            recipient: owner,
            calculated_amount_threshold: second_expected_output
                .low, // threshold is min amount of received tokens
        );

    let eth_gained = eth.balance_of(owner) - balance_eth_before;
    assert(eth_gained >= second_expected_output, 'swap output too low');
//TODO(ekubo): handle locking of NFT
}

#[test]
#[fork("Mainnet")]
fn test_ekubo_launch_meme_token0_pool_1_percent() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };
    let launchpad_address = EKUBO_LAUNCHER_ADDRESS();
    let ekubo_launchpad = IEkuboLauncherDispatcher { contract_address: launchpad_address };

    let unlock_time = starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME;

    // 1% fee, 0.6% tick spacing, starting tick is a price of 100 MEME / ETH
    let (fee, tick_spacing, starting_tick, bound) = (
        0x28f5c28f5c28f600000000000000000, 5982, 4600158, 88719042
    );
    let liquidity_position = memecoin
        .launch_memecoin(
            SupportedExchanges::Ekubo,
            ETH_ADDRESS(),
            unlock_time,
            array![fee, tick_spacing, starting_tick, bound].span()
        );
    let pair_address = match liquidity_position {
        LiquidityPosition::ERC20(_) => panic_with_felt252('Expected NFT position'),
        LiquidityPosition::NFT(id) => id,
    };

    // Test that swaps work correctly

    let (token0, token1) = sort_tokens(eth.contract_address, memecoin_address);

    let pool_key = PoolKey {
        token0: token0,
        token1: token1,
        fee: fee.try_into().unwrap(),
        tick_spacing: tick_spacing.try_into().unwrap(),
        extension: 0.try_into().unwrap(),
    };

    let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    let liquidity = core.get_pool_liquidity(pool_key);
    let price = core.get_pool_price(pool_key);
    let reserve_memecoin = core.get_reserves(memecoin_address);
    let reserve_fake_eth = core.get_reserves(ETH_ADDRESS());
    assert(reserve_fake_eth == 0, 'reserve counterparty not 0');

    // Verify that the reserve of memecoin is within 0.5% of the (total supply minus the team allocation)
    let team_alloc = memecoin.get_team_allocation();
    let expected_reserve_lower_bound = PercentageMath::percent_mul(
        memecoin.totalSupply() - team_alloc, 9950,
    );
    assert(reserve_memecoin > expected_reserve_lower_bound, 'reserves holds too few token');

    // Check that swaps work correctly

    // First swap:

    // We swap ETH (token1) for MEME (token0)
    // The initial price of the pool is ~100MEME/ETH
    // so the received amounts should be around 100x the amount of ETH sent
    // with a 5% margin of error for the price impact.
    let swapper_address = deploy_ekubo_swapper();
    let ekubo_swapper = ISimpleSwapperDispatcher { contract_address: swapper_address };
    let first_amount_in = 2 * pow_256(10, 16); // The initial price was fixed
    let swap_params = SwapParameters {
        amount: i129 { mag: first_amount_in.low, sign: false // positive sign is exact input
         },
        is_token1: true,
        sqrt_ratio_limit: 3228201981189909664284139725369263521792, // 90 meme /eth
        skip_ahead: 0,
    };

    // We transfer tokens to the swapper contract, which performs the swap
    // This is required the way the swapper contract is coded.
    // It then sends back the funds to the caller
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.transfer(swapper_address, first_amount_in);
    stop_prank(CheatTarget::One(eth.contract_address));

    // We expect to receive 100x the amount of ETH sent with a 5% margin of error
    let expected_output = PercentageMath::percent_mul(100 * first_amount_in, 9500);
    ekubo_swapper
        .swap(
            pool_key: pool_key,
            swap_params: swap_params,
            recipient: owner,
            calculated_amount_threshold: expected_output
                .low, // threshold is min amount of received tokens
        );

    assert(memecoin.balance_of(owner) >= expected_output, 'swap output too low');
    // Second swap:

    // We swap MEME (token0) for ETH (token1)
    // The initial price of the pool is ~100MEME/ETH
    // so the received amounts should be around 1/100 of the amount of MEME sent
    // the only difference is that the expect amount should be the initial amount,
    // minus the fees of the pool.
    let second_amount_in = memecoin.balance_of(owner);
    let swap_params = SwapParameters {
        amount: i129 { mag: second_amount_in.low, sign: false // exact input
         },
        is_token1: false,
        sqrt_ratio_limit: 18446748437148339061, // 110 meme / eth
        skip_ahead: 0,
    };
    // with a 1% fee we should receive ~2% less than the initial amount
    let second_expected_output = PercentageMath::percent_mul(first_amount_in, 9800);
    let balance_eth_before = eth.balance_of(owner);

    start_prank(CheatTarget::One(memecoin_address), owner);
    memecoin.transfer(swapper_address, second_amount_in);
    stop_prank(CheatTarget::One(memecoin_address));

    ekubo_swapper
        .swap(
            pool_key: pool_key,
            swap_params: swap_params,
            recipient: owner,
            calculated_amount_threshold: second_expected_output
                .low, // threshold is min amount of received tokens
        );

    let eth_gained = eth.balance_of(owner) - balance_eth_before;
    assert(eth_gained >= second_expected_output, 'swap output too low');
//TODO(ekubo): handle locking of NFT
}


#[test]
#[fork("Mainnet")]
fn test_ekubo_launch_meme_token1_and_swap() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let (TOKEN0, _) = deploy_token0_with_owner(owner);
    let launchpad_address = EKUBO_LAUNCHER_ADDRESS();
    let ekubo_launchpad = IEkuboLauncherDispatcher { contract_address: launchpad_address };

    let unlock_time = starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME;
    // 0.3% fee, 0.6% tick spacing, starting tick is a price of 100 MEME / ETH
    // the starting tick should be computed base on wanted initial price liquidity
    // initial price set at 100MEME/ETH -> 0.01ETH/MEME
    // exact_value = math.log(initial_price,1.000001)
    // initial_tick = (exact_value // tick_spacing)*tick_spacing
    // The sign of the tick doesn't matter as it's handled by the cairo contract
    let (fee, tick_spacing, starting_tick, bound) = (
        0xc49ba5e353f7d00000000000000000, 5982, 4600158, 88719042
    );
    let liquidity_position = memecoin
        .launch_memecoin(
            SupportedExchanges::Ekubo,
            TOKEN0.contract_address,
            unlock_time,
            array![fee, tick_spacing, starting_tick, bound].span()
        );
    let pair_address = match liquidity_position {
        LiquidityPosition::ERC20(_) => panic_with_felt252('Expected NFT position'),
        LiquidityPosition::NFT(id) => id,
    };

    // Test that swaps work correctly

    let (token0_address, token1_address) = sort_tokens(TOKEN0.contract_address, memecoin_address);
    assert(token0_address == TOKEN0.contract_address, 'token0 not TOKEN0');

    // Hardcoded fee and tick_spacing
    let pool_key = PoolKey {
        token0: token0_address,
        token1: token1_address,
        fee: fee.try_into().unwrap(), //0.3%
        tick_spacing: tick_spacing.try_into().unwrap(), // 0.6%
        extension: 0.try_into().unwrap(),
    };

    let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    let liquidity = core.get_pool_liquidity(pool_key);
    let price = core.get_pool_price(pool_key);
    let reserve_memecoin = core.get_reserves(memecoin_address);
    let reserve_token0 = core.get_reserves(TOKEN0_ADDRESS());
    assert(reserve_token0 == 0, 'reserve counterparty not 0');

    // Verify that the reserve of memecoin is within 0.5% of the (total supply minus the team allocation)
    let team_alloc = memecoin.get_team_allocation();
    let expected_reserve_lower_bound = PercentageMath::percent_mul(
        memecoin.totalSupply() - team_alloc, 9950,
    );
    assert(reserve_memecoin > expected_reserve_lower_bound, 'reserves holds too few token');

    // Check that swaps work correctly

    // First swap:

    // We swap MEME (token1) for TOKEN0 (token0)
    // The initial price of the pool is ~100MEME/TOKEN0 = 0.01 TOKEN0/MEME
    // so the received amounts should be around 0.01x the amount of ETH sent
    // with a 5% margin of error for the price impact.
    let swapper_address = deploy_ekubo_swapper();
    let ekubo_swapper = ISimpleSwapperDispatcher { contract_address: swapper_address };
    let first_amount_in = 200 * pow_256(10, 16); // The initial price was fixed
    let swap_params = SwapParameters {
        amount: i129 { mag: first_amount_in.low, sign: false // positive sign is exact input
         },
        is_token1: false,
        sqrt_ratio_limit: 18446748437148339061, // lower than current
        skip_ahead: 0,
    };

    // We transfer tokens to the swapper contract, which performs the swap
    // This is required the way the swapper contract is coded.
    // It then sends back the funds to the caller
    start_prank(CheatTarget::One(TOKEN0.contract_address), owner);
    TOKEN0.transfer(swapper_address, first_amount_in);
    stop_prank(CheatTarget::One(TOKEN0.contract_address));

    // We expect to receive 0.01x the amount of TOKEN0 sent with a 5% margin of error
    let expected_output = PercentageMath::percent_mul(first_amount_in, 95);
    ekubo_swapper
        .swap(
            pool_key: pool_key,
            swap_params: swap_params,
            recipient: owner,
            calculated_amount_threshold: expected_output
                .low, // threshold is min amount of received tokens
        );

    assert(memecoin.balance_of(owner) >= expected_output, 'swap output too low');
    // Second swap:

    // We swap MEME (token0) for ETH (token1)
    // The initial price of the pool is ~0.01TOKEN0/memecoin
    // so the received amounts should be around 100x of the amount of MEME sent
    // the only difference is that the expect amount should be the initial amount,
    // minus the fees of the pool.

    let second_amount_in = memecoin.balance_of(owner);
    let swap_params = SwapParameters {
        amount: i129 { mag: second_amount_in.low, sign: false // exact input
         },
        is_token1: true,
        sqrt_ratio_limit: 6277100250585753475930931601400621808602321654880405518632, // higher than current
        skip_ahead: 0,
    };
    let second_expected_output = PercentageMath::percent_mul(first_amount_in, 9900);
    let balance_TOKEN0_before = TOKEN0.balance_of(owner);

    start_prank(CheatTarget::One(memecoin_address), owner);
    memecoin.transfer(swapper_address, second_amount_in);
    stop_prank(CheatTarget::One(memecoin_address));

    ekubo_swapper
        .swap(
            pool_key: pool_key,
            swap_params: swap_params,
            recipient: owner,
            calculated_amount_threshold: second_expected_output
                .low, // threshold is min amount of received tokens
        );

    let TOKEN0_gained = TOKEN0.balance_of(owner) - balance_TOKEN0_before;
    assert(TOKEN0_gained >= second_expected_output, 'swap output too low');
//TODO(ekubo): handle locking of NFT
}
//TODO! As there are no unit ekubo tests, we need to deeply test the whole flow of interaction with ekubo - including 
//TODO! launching with wrong parameters, as the frontend data cant be trusted


