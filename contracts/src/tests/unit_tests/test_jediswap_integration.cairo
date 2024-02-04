use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{
    TxInfoMockTrait, start_spoof, stop_spoof, start_prank, stop_prank, start_warp, stop_warp,
    CheatTarget
};
//TODO! Due to the bug in fork_tests/test_jediswap,
// we deploy the contracts here instead of using the forked test.

use unruggable::exchanges::jediswap_adapter::{
    IJediswapFactoryDispatcher, IJediswapFactoryDispatcherTrait, IJediswapRouterDispatcher,
    IJediswapRouterDispatcherTrait, IJediswapPairDispatcher, IJediswapPairDispatcherTrait,
};
use unruggable::factory::{LaunchParameters, IFactoryDispatcher, IFactoryDispatcherTrait};
use unruggable::locker::interface::{
    ILockManagerDispatcher, ILockManagerDispatcherTrait, LockPosition
};
use unruggable::tests::addresses::{JEDI_ROUTER_ADDRESS};
use unruggable::tests::unit_tests::utils::{
    deploy_memecoin_through_factory_with_owner, TRANSFER_RESTRICTION_DELAY,
    MAX_PERCENTAGE_BUY_LAUNCH, deploy_eth_with_owner, MEMEFACTORY_ADDRESS, LOCK_MANAGER_ADDRESS,
    DEFAULT_MIN_LOCKTIME, pow_256, deploy_jedi_amm_factory_and_router, deploy_meme_factory,
    deploy_eth, ETH_ADDRESS, INITIAL_HOLDERS, INITIAL_HOLDERS_AMOUNTS
};
use unruggable::token::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

#[test]
fn test_jediswap_integration() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };
    let router = IJediswapRouterDispatcher { contract_address: JEDI_ROUTER_ADDRESS() };

    // approve spending of eth by factory
    let eth_amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    let factory_balance_meme = memecoin.balanceOf(factory.contract_address);
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(factory.contract_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(factory.contract_address), owner);
    // Set non-zero timestamp as the is_launched check is based on block timestamp
    start_warp(CheatTarget::One(memecoin_address), 1);
    let pair_address = factory
        .launch_on_jediswap(
            LaunchParameters {
                memecoin_address,
                transfer_restriction_delay: TRANSFER_RESTRICTION_DELAY,
                max_percentage_buy_launch: MAX_PERCENTAGE_BUY_LAUNCH,
                quote_address: eth.contract_address,
                initial_holders: INITIAL_HOLDERS(),
                initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            },
            eth_amount,
            DEFAULT_MIN_LOCKTIME,
        );
    stop_prank(CheatTarget::One(factory.contract_address));
    stop_warp(CheatTarget::One(memecoin_address));

    // Approve required token amounts
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(JEDI_ROUTER_ADDRESS(), 1 * pow_256(10, 18));
    stop_prank(CheatTarget::One(eth.contract_address));

    // Max buy cap is `MAX_PERCENTAGE_BUY_LAUNCH` of total supply
    // Initial rate is roughly 1 ETH for 21M meme,
    // so if max buy is ~ 2% of 1 ETH = 0.02 ETH
    let amount_in = MAX_PERCENTAGE_BUY_LAUNCH.into() * pow_256(10, 14);
    start_prank(CheatTarget::One(router.contract_address), owner);
    let first_swap = router
        .swap_exact_tokens_for_tokens(
            amountIn: amount_in,
            amountOutMin: 0,
            path: array![eth.contract_address, memecoin_address],
            to: owner,
            deadline: starknet::get_block_timestamp()
        );
    stop_prank(CheatTarget::One(router.contract_address));

    let first_out = *first_swap[0];

    start_prank(CheatTarget::One(memecoin_address), owner);
    memecoin.approve(router.contract_address, first_out);
    stop_prank(CheatTarget::One(memecoin_address));

    let balanceofOwnermemecoin = memecoin.balanceOf(owner);

    start_prank(CheatTarget::One(router.contract_address), owner);
    let _second_swap = router
        .swap_exact_tokens_for_tokens(
            amountIn: first_out,
            amountOutMin: 0,
            path: array![memecoin_address, eth.contract_address],
            to: owner,
            deadline: starknet::get_block_timestamp() + 10000
        );
    stop_prank(CheatTarget::One(router.contract_address));

    // Check token lock
    let pair = IJediswapPairDispatcher { contract_address: pair_address };
    let locker = ILockManagerDispatcher { contract_address: LOCK_MANAGER_ADDRESS() };
    let lock_address = locker.user_lock_at(owner, 0);
    let token_lock = locker.get_lock_details(lock_address);
    let expected_lock = LockPosition {
        token: pair_address,
        amount: pair.totalSupply() - 1000, // upon first mint, 1000 lp tokens are burnt
        unlock_time: starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME,
        owner: owner,
    };

    assert(token_lock == expected_lock, 'token lock details wrong');
}
