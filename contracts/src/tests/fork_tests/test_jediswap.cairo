use debug::PrintTrait;
use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{start_prank, stop_prank, CheatTarget};
use unruggable::exchanges::SupportedExchanges;
use unruggable::exchanges::jediswap_adapter::{
    IJediswapFactoryDispatcher, IJediswapFactoryDispatcherTrait, IJediswapRouterDispatcher,
    IJediswapRouterDispatcherTrait, IJediswapPairDispatcher, IJediswapPairDispatcherTrait,
};
use unruggable::locker::LockPosition;
use unruggable::locker::interface::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::tests::addresses::{JEDI_FACTORY_ADDRESS, JEDI_ROUTER_ADDRESS, ETH_ADDRESS};
use unruggable::tests::fork_tests::utils::{deploy_memecoin_through_factory_with_owner, sort_tokens};
use unruggable::tests::unit_tests::utils::{
    OWNER, DEFAULT_MIN_LOCKTIME, pow_256, LOCK_MANAGER_ADDRESS
};
use unruggable::tokens::interface::{IUnruggableMemecoinDispatcherTrait};
use unruggable::utils::math::PercentageMath;

#[test]
#[fork("Mainnet")]
fn test_jediswap_integration() {
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(OWNER());
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };
    let router = IJediswapRouterDispatcher { contract_address: JEDI_ROUTER_ADDRESS() };

    let unlock_time = starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME;

    start_prank(CheatTarget::One(memecoin_address), OWNER());
    let pair_address = memecoin
        .launch_memecoin(SupportedExchanges::JediSwap, ETH_ADDRESS(), unlock_time);
    stop_prank(CheatTarget::One(memecoin_address));
    let pair = IJediswapPairDispatcher { contract_address: pair_address };

    // Test that swaps work correctly

    // Approve required token amounts
    start_prank(CheatTarget::One(eth.contract_address), OWNER());
    eth.approve(JEDI_ROUTER_ADDRESS(), 1 * pow_256(10, 18));
    stop_prank(CheatTarget::One(eth.contract_address));

    // Max buy cap is 2% of total supply
    // Initial rate is roughly 1 ETH for 21M meme,
    // so max buy is ~ 2% of 1 ETH = 0.02 ETH
    let amount_in = 2 * pow_256(10, 16);
    start_prank(CheatTarget::One(router.contract_address), OWNER());
    let first_swap = router
        .swap_exact_tokens_for_tokens(
            amountIn: amount_in,
            amountOutMin: 0,
            path: array![ETH_ADDRESS(), memecoin_address],
            to: OWNER(),
            deadline: starknet::get_block_timestamp()
        );
    let first_out = *first_swap[0];

    start_prank(CheatTarget::One(memecoin_address), OWNER());
    memecoin.approve(JEDI_ROUTER_ADDRESS(), first_out);
    stop_prank(CheatTarget::One(eth.contract_address));

    let _second_swap = router
        .swap_exact_tokens_for_tokens(
            amountIn: first_out,
            amountOutMin: 0,
            path: array![memecoin_address, ETH_ADDRESS()],
            to: OWNER(),
            deadline: starknet::get_block_timestamp()
        );

    // Check token lock
    let locker = ILockManagerDispatcher { contract_address: LOCK_MANAGER_ADDRESS() };
    let lock_address = locker.user_lock_at(OWNER(), 0);
    let token_lock = locker.get_lock_details(lock_address);
    let expected_lock = LockPosition {
        token: pair_address,
        amount: pair.totalSupply(),
        unlock_time: starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME,
        owner: OWNER(),
    };

    // The lock position is supposed to reflect accrual from LP fees
    assert(token_lock == expected_lock, 'Token lock not matching expect');
}
