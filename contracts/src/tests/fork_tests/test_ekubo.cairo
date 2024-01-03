use debug::PrintTrait;
use ekubo::interfaces::core::{ICoreDispatcher, ICoreDispatcherTrait};
use ekubo::types::keys::PoolKey;
use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{start_prank, stop_prank, CheatTarget};
use unruggable::exchanges::SupportedExchanges;
use unruggable::exchanges::ekubo::launchpad::{ILaunchpadDispatcher, ILaunchpadDispatcherTrait};
use unruggable::locker::LockPosition;
use unruggable::locker::interface::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::tests::addresses::{ETH_ADDRESS, EKUBO_CORE};
use unruggable::tests::fork_tests::utils::{
    deploy_memecoin_through_factory_with_owner, sort_tokens, LAUNCHPAD_ADDRESS,
    EKUBO_SWAPPER_ADDRESS, deploy_ekubo_swapper
};
use unruggable::tests::unit_tests::utils::{
    OWNER, DEFAULT_MIN_LOCKTIME, pow_256, LOCK_MANAGER_ADDRESS
};
use unruggable::tokens::interface::{IUnruggableMemecoinDispatcherTrait};
use unruggable::tokens::memecoin::LiquidityPosition;
use unruggable::utils::math::PercentageMath;
use unruggable::mocks::ekubo::swapper::{
    SwapParameters, ISimpleSwapperDispatcher, ISimpleSwapperDispatcherTrait
};
use ekubo::types::i129::i129;

#[test]
#[fork("Mainnet")]
fn test_ekubo_launch_meme_token0() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };
    let launchpad_address = LAUNCHPAD_ADDRESS();
    let ekubo_launchpad = ILaunchpadDispatcher { contract_address: launchpad_address };

    let unlock_time = starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME;

    let liquidity_position = memecoin
        .launch_memecoin(SupportedExchanges::Ekubo, ETH_ADDRESS(), unlock_time);
    let pair_address = match liquidity_position {
        LiquidityPosition::ERC20(_) => panic_with_felt252('Expected NFT position'),
        LiquidityPosition::NFT(id) => id,
    };

    // Test that swaps work correctly

    let (token0, token1) = sort_tokens(eth.contract_address, memecoin_address);
    let pool_key = PoolKey {
        token0: token0,
        token1: token1,
        fee: 0xc49ba5e353f7d00000000000000000, //0.3%
        tick_spacing: 5982, // 0.6%
        extension: 0.try_into().unwrap(),
    };

    let core = ICoreDispatcher { contract_address: EKUBO_CORE() };
    let liquidity = core.get_pool_liquidity(pool_key);
    let price = core.get_pool_price(pool_key);
    let reserve_memecoin = core.get_reserves(memecoin_address);
    let reserve_fake_eth = core.get_reserves(ETH_ADDRESS());
    assert(reserve_fake_eth == 0, 'reserve counterparty not 0');

    let team_alloc = memecoin.get_team_allocation();
    assert(
        reserve_memecoin == memecoin.totalSupply() - team_alloc, 'reserves dont have all supply'
    );

    // Check that swaps work correctly
    let swapper_address = deploy_ekubo_swapper();
    let ekubo_swapper = ISimpleSwapperDispatcher { contract_address: swapper_address };
    let amount_in = 2 * pow_256(10, 16); // The initial price was fixed
    // let swap_params = SwapParameters {
    //     amount: i129 {
    //         mag: amount_in.low,
    //         sign: false // positive sign is exact input
    //     },
    // is_token1: false,
    // sqrt_ratio_limit: u256,
    // skip_ahead: u32,
    // }
    // ekubo_swapper.swap(
    //     pool_key: pool_key,
    //     swap_params: SwapParameters {}
    // )

    // Approve required token amounts
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(launchpad_address, 1 * pow_256(10, 18));
    stop_prank(CheatTarget::One(eth.contract_address));
//TODO: these are hardcoded values, they should be returned from the launched memecoin.
// Max buy cap is 2% of total supply
// Initial rate is roughly 1 ETH for 21M meme,
// so max buy is ~ 2% of 1 ETH = 0.02 ETH

// start_prank(CheatTarget::One(router.contract_address), OWNER());
// let first_swap = router
//     .swap_exact_tokens_for_tokens(
//         amountIn: amount_in,
//         amountOutMin: 0,
//         path: array![ETH_ADDRESS(), memecoin_address],
//         to: OWNER(),
//         deadline: starknet::get_block_timestamp()
//     );
// let first_out = *first_swap[0];
// start_prank(CheatTarget::One(memecoin_address), OWNER());
// memecoin.approve(JEDI_ROUTER_ADDRESS(), first_out);
// stop_prank(CheatTarget::One(eth.contract_address));

// let _second_swap = router
//     .swap_exact_tokens_for_tokens(
//         amountIn: first_out,
//         amountOutMin: 0,
//         path: array![memecoin_address, ETH_ADDRESS()],
//         to: OWNER(),
//         deadline: starknet::get_block_timestamp()
//     );

// // Check token lock
// let locker = ILockManagerDispatcher { contract_address: LOCK_MANAGER_ADDRESS() };
// let lock_address = locker.user_lock_at(OWNER(), 0);
// let token_lock = locker.get_lock_details(lock_address);
// let expected_lock = LockPosition {
//     token: pair_address,
//     amount: pair.totalSupply(),
//     unlock_time: starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME,
//     owner: OWNER(),
// };

// assert(token_lock.token == expected_lock.token, 'token not locked');
// // can't test for the amount locked as the initial liq provided and the total supply
// // of the pair do not match
// assert(token_lock.unlock_time == expected_lock.unlock_time, 'wrong unlock time');
// assert(token_lock.owner == expected_lock.owner, 'wrong owner');
}
//TODO! As there are no unit ekubo tests, we need to deeply test the whole flow of interaction with ekubo - including 
//TODO! launching with wrong parameters, as the frontend data cant be trusted


