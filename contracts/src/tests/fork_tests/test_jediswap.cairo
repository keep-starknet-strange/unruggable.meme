use debug::PrintTrait;
use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{start_prank, stop_prank, CheatTarget, TxInfoMockTrait, start_spoof, stop_spoof};
use unruggable::exchanges::SupportedExchanges;
use unruggable::exchanges::jediswap_adapter::{
    IJediswapFactoryDispatcher, IJediswapFactoryDispatcherTrait, IJediswapRouterDispatcher,
    IJediswapRouterDispatcherTrait, IJediswapPairDispatcher, IJediswapPairDispatcherTrait,
};
use unruggable::factory::interface::{IFactoryDispatcher, IFactoryDispatcherTrait};
use unruggable::locker::LockPosition;
use unruggable::locker::interface::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::tests::addresses::{JEDI_FACTORY_ADDRESS, JEDI_ROUTER_ADDRESS, ETH_ADDRESS};
use unruggable::tests::fork_tests::utils::{deploy_memecoin_through_factory_with_owner, sort_tokens};
use unruggable::tests::unit_tests::utils::{
    OWNER, DEFAULT_MIN_LOCKTIME, pow_256, LOCK_MANAGER_ADDRESS, MEMEFACTORY_ADDRESS,
    deploy_eth_with_owner, TRANSFER_RESTRICTION_DELAY, MAX_PERCENTAGE_BUY_LAUNCH
};
use unruggable::token::interface::{IUnruggableMemecoinDispatcherTrait};
use unruggable::token::memecoin::LiquidityType;
use unruggable::utils::math::PercentageMath;

//TODO! This test cannot pass due to a bug in starknet foundry
// when mocking the tx_hash during interactions with Cairo0 contracts.
// #[test]
// #[fork("Mainnet")]
// fn test_jediswap_integration() {
//     let owner = snforge_std::test_address();
//     let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
//     let (quote, quote_address) = deploy_eth_with_owner(owner);
//     let router = IJediswapRouterDispatcher { contract_address: JEDI_ROUTER_ADDRESS() };
//     let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
//     // Test that swaps work correctly
//     // Mock the txInfo, as the base tx_hash_tracker value is 0
//     // and will thus prevent this transaction
//     let mut tx_info = TxInfoMockTrait::default();
//     tx_info.transaction_hash = Option::Some(1234);
//     start_spoof(CheatTarget::All, tx_info);

//     let unlock_time = starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME;

//     // approve spending of eth by factory
//     let amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
//     start_prank(CheatTarget::One(quote.contract_address), owner);
//     quote.approve(factory.contract_address, amount);
//     stop_prank(CheatTarget::One(quote.contract_address));

//     let pair_address = factory
//         .launch_on_jediswap(
//             memecoin_address,
//             TRANSFER_RESTRICTION_DELAY,
//             MAX_PERCENTAGE_BUY_LAUNCH,
//             quote_address,
//             amount,
//             unlock_time
//         );

//     let pair = IJediswapPairDispatcher { contract_address: pair_address };

//     // Approve required token amounts
//     start_prank(CheatTarget::One(quote.contract_address), owner);
//     quote.approve(JEDI_ROUTER_ADDRESS(), 1 * pow_256(10, 18));
//     stop_prank(CheatTarget::One(quote.contract_address));

//     // Max buy cap is `MAX_PERCENTAGE_BUY_LAUNCH` of total supply
//     // Initial rate is roughly 1 ETH for 21M meme,
//     // so if max buy is ~ 2% of 1 ETH = 0.02 ETH
//     let amount_in = MAX_PERCENTAGE_BUY_LAUNCH.into() * pow_256(10, 14);
//     start_prank(CheatTarget::One(router.contract_address), owner);
//     let first_swap = router
//         .swap_exact_tokens_for_tokens(
//             amountIn: amount_in,
//             amountOutMin: 0,
//             path: array![quote_address, memecoin_address],
//             to: owner,
//             deadline: starknet::get_block_timestamp()
//         );
//     let first_out = *first_swap[0];

//     start_prank(CheatTarget::One(memecoin_address), owner);
//     memecoin.approve(JEDI_ROUTER_ADDRESS(), first_out);
//     stop_prank(CheatTarget::One(quote.contract_address));

//     let _second_swap = router
//         .swap_exact_tokens_for_tokens(
//             amountIn: first_out,
//             amountOutMin: 0,
//             path: array![memecoin_address, quote_address],
//             to: owner,
//             deadline: starknet::get_block_timestamp()
//         );

//     // Check token lock
//     let locker = ILockManagerDispatcher { contract_address: LOCK_MANAGER_ADDRESS() };
//     let lock_address = locker.user_lock_at(owner, 0);
//     let token_lock = locker.get_lock_details(lock_address);
//     let expected_lock = LockPosition {
//         token: pair_address,
//         amount: pair.totalSupply() - 1000, // upon first mint, 1000 lp tokens are burnt
//         unlock_time: starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME,
//         owner: owner,
//     };

//     assert(token_lock == expected_lock, 'token lock details wrong');
// }

#[test]
#[fork("Mainnet")]
#[should_panic(expected: ('Max buy cap reached',))]
fn test_buy_above_max_limit_should_fail() {
    //* Setup
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let (quote, quote_address) = deploy_eth_with_owner(owner);
    let router = IJediswapRouterDispatcher { contract_address: JEDI_ROUTER_ADDRESS() };
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };

    let unlock_time = starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME;

    // approve spending of eth by factory
    let amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    start_prank(CheatTarget::One(quote.contract_address), owner);
    quote.approve(factory.contract_address, amount);
    stop_prank(CheatTarget::One(quote.contract_address));

    let pair_address = factory
        .launch_on_jediswap(
            memecoin_address,
            TRANSFER_RESTRICTION_DELAY,
            MAX_PERCENTAGE_BUY_LAUNCH,
            quote_address,
            amount,
            unlock_time
        );

    let pair = IJediswapPairDispatcher { contract_address: pair_address };

    // * Test

    // Approve required token amounts
    start_prank(CheatTarget::One(quote.contract_address), owner);
    quote.approve(JEDI_ROUTER_ADDRESS(), 1 * pow_256(10, 18));
    stop_prank(CheatTarget::One(quote.contract_address));

    let amount_in = 2 * pow_256(10, 17); // @audit Bigger amount
    start_prank(CheatTarget::One(router.contract_address), owner);
    let first_swap = router
        .swap_exact_tokens_for_tokens(
            amountIn: amount_in,
            amountOutMin: 0,
            path: array![quote_address, memecoin_address],
            to: owner,
            deadline: starknet::get_block_timestamp()
        );
}
