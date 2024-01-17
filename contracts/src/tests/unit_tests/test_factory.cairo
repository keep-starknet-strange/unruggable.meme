use core::option::OptionTrait;
use ekubo::types::i129::i129;
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, start_warp, stop_warp, start_roll, stop_roll
};
use starknet::{ContractAddress, contract_address_const};
use unruggable::exchanges::ekubo_adapter::EkuboPoolParameters;

use unruggable::exchanges::jediswap_adapter::{
    IJediswapFactory, IJediswapFactoryDispatcher, IJediswapFactoryDispatcherTrait, IJediswapRouter,
    IJediswapRouterDispatcher, IJediswapRouterDispatcherTrait, IJediswapPairDispatcher,
    IJediswapPairDispatcherTrait
};
use unruggable::exchanges::{SupportedExchanges};
use unruggable::factory::{IFactory, IFactoryDispatcher, IFactoryDispatcherTrait, LaunchParameters};
use unruggable::locker::interface::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::locker::{LockPosition};
use unruggable::tests::addresses::{ETH_ADDRESS, JEDI_FACTORY_ADDRESS};
use unruggable::tests::unit_tests::utils::{
    deploy_jedi_amm_factory_and_router, deploy_meme_factory, deploy_locker, deploy_eth, OWNER, NAME,
    SYMBOL, DEFAULT_INITIAL_SUPPLY, INITIAL_HOLDERS, INITIAL_HOLDERS_AMOUNTS, SALT,
    deploy_memecoin_through_factory, MEMEFACTORY_ADDRESS,
    deploy_token_from_class_at_address_with_owner, deploy_memecoin_through_factory_with_owner,
    pow_256, LOCK_MANAGER_ADDRESS, DEFAULT_MIN_LOCKTIME, deploy_and_launch_memecoin,
    TRANSFER_RESTRICTION_DELAY, MAX_PERCENTAGE_BUY_LAUNCH
};
use unruggable::token::interface::{
    IUnruggableMemecoin, IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};
use unruggable::utils::sum;
use unruggable::token::memecoin::{LiquidityType, LiquidityParameters};


#[test]
fn test_locked_liquidity_not_locked() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };

    assert(factory.locked_liquidity(memecoin_address).is_none(), 'liquidty not locked yet');
}

#[test]
fn test_locked_liquidity_jediswap() {
    let (memecoin, memecoin_address) = deploy_and_launch_memecoin();
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };

    let (locker_address, locked_type) = factory.locked_liquidity(memecoin_address).unwrap();
    assert(locker_address == LOCK_MANAGER_ADDRESS(), 'wrong locker address');
    match locked_type {
        LiquidityType::JediERC20(_) => (),
        LiquidityType::EkuboNFT(_) => panic_with_felt252('wrong liquidity type')
    }
}

// Test for ekubo is in fork tests

#[test]
fn test_exchange_address() {
    let (_, router_address) = deploy_jedi_amm_factory_and_router();
    let memecoin_factory_address = deploy_meme_factory(router_address);
    let memecoin_factory = IFactoryDispatcher { contract_address: memecoin_factory_address };

    let exchange_address = memecoin_factory.exchange_address(SupportedExchanges::Jediswap);
    assert(exchange_address == router_address, 'wrong amm router_address');
}

#[test]
fn test_is_memecoin() {
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory();
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };

    assert(factory.is_memecoin(address: memecoin_address), 'should be memecoin');
    assert(
        !factory.is_memecoin(address: 'random address'.try_into().unwrap()),
        'should not be memecoin'
    );
}


#[test]
fn test_create_memecoin() {
    // Required contracts
    let (_, router_address) = deploy_jedi_amm_factory_and_router();
    let memecoin_factory_address = deploy_meme_factory(router_address);
    let memecoin_factory = IFactoryDispatcher { contract_address: memecoin_factory_address };
    let (eth, eth_address) = deploy_eth();

    let eth_amount: u256 = eth.total_supply() / 2; // 50% of supply

    start_prank(CheatTarget::One(eth.contract_address), OWNER());
    eth.approve(memecoin_factory_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(memecoin_factory.contract_address), OWNER());
    let memecoin_address = memecoin_factory
        .create_memecoin(
            owner: OWNER(),
            name: NAME(),
            symbol: SYMBOL(),
            initial_supply: DEFAULT_INITIAL_SUPPLY(),
            contract_address_salt: SALT(),
        );
    stop_prank(CheatTarget::One(memecoin_factory.contract_address));

    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

    assert(memecoin.name() == NAME(), 'wrong memecoin name');
    assert(memecoin.symbol() == SYMBOL(), 'wrong memecoin symbol');
    assert_eq!(memecoin.balanceOf(memecoin_factory_address), DEFAULT_INITIAL_SUPPLY(),);
}

#[test]
fn test_launch_memecoin_happy_path() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };
    let block_number = 42;

    // approve spending of eth by factory
    let eth_amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    let factory_balance_meme = memecoin.balanceOf(factory.contract_address);
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(factory.contract_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(factory.contract_address), owner);
    start_warp(CheatTarget::One(memecoin_address), 1);
    start_roll(CheatTarget::One(memecoin_address), block_number);
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
    stop_roll(CheatTarget::One(memecoin_address));

    assert(memecoin.is_launched(), 'should be launched');
    assert(memecoin.launched_at_block_number() == block_number, 'bad block number');

    // Check pair creation
    let team_allocation = sum(INITIAL_HOLDERS_AMOUNTS());
    let pair = IJediswapPairDispatcher { contract_address: pair_address };
    let (token_0_reserves, token_1_reserves, _) = pair.get_reserves();
    assert(pair.token0() == memecoin_address, 'wrong token 0 address');
    assert(pair.token1() == eth.contract_address, 'wrong token 1 address');
    assert(token_0_reserves == factory_balance_meme - team_allocation, 'wrong pool token reserves');
    assert(token_1_reserves == eth_amount, 'wrong pool memecoin reserves');
    let lp_token = ERC20ABIDispatcher { contract_address: pair_address };
    assert(lp_token.balanceOf(memecoin_address) == 0, 'shouldnt have lp tokens');

    // Check token lock
    let locker = ILockManagerDispatcher { contract_address: LOCK_MANAGER_ADDRESS() };
    let lock_address = locker.user_lock_at(owner, 0);
    let token_lock = locker.get_lock_details(lock_address);
    let expected_lock = LockPosition {
        token: pair_address,
        amount: pair.totalSupply() - 1000,
        unlock_time: starknet::get_block_timestamp() + DEFAULT_MIN_LOCKTIME,
        owner: owner,
    };
    assert(token_lock == expected_lock, 'wrong lock');

    // Check ownership renounced
    assert(memecoin.owner().is_zero(), 'Still an owner');
}

#[test]
fn test_launch_memecoin_with_jediswap_parameters() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };

    // approve spending of eth by factory
    let eth_amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    let factory_balance_meme = memecoin.balanceOf(factory.contract_address);
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(factory.contract_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(factory.contract_address), owner);
    let pair_address = factory
        .launch_on_jediswap(
            memecoin_address,
            TRANSFER_RESTRICTION_DELAY,
            MAX_PERCENTAGE_BUY_LAUNCH,
            eth.contract_address,
            eth_amount,
            DEFAULT_MIN_LOCKTIME,
        );
    stop_prank(CheatTarget::One(factory.contract_address));

    let liquidity_parameters = memecoin.launched_with_liquidity_parameters().unwrap();

    match liquidity_parameters {
        LiquidityParameters::Ekubo(_) => panic_with_felt252('wrong liquidity parameters type'),
        LiquidityParameters::Jediswap(jediswap_liquidity_parameters) => {
            assert(jediswap_liquidity_parameters.quote_address == eth.contract_address, 'Bad quote address');
            assert(jediswap_liquidity_parameters.quote_amount == eth_amount, 'Bad quote amount');
        }
    }
}

#[test]
fn test_launch_memecoin_with_ekubo_parameters() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };

    let fee = 0xc49ba5e353f7d00000000000000000;
    let tick_spacing = 5982;
    let starting_tick = i129 { sign: true, mag: 4600158 }; // 0.01ETH/MEME
    let bound = 88719042;

    // approve spending of eth by factory
    let eth_amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    let factory_balance_meme = memecoin.balanceOf(factory.contract_address);
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(factory.contract_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(factory.contract_address), owner);
    let pair_address = factory
        .launch_on_ekubo(
            memecoin_address,
            TRANSFER_RESTRICTION_DELAY,
            MAX_PERCENTAGE_BUY_LAUNCH,
            eth.contract_address,
            EkuboPoolParameters {
                fee,
                tick_spacing,
                starting_tick,
                bound
            }
        );
    stop_prank(CheatTarget::One(factory.contract_address));

    let liquidity_parameters = memecoin.launched_with_liquidity_parameters().unwrap();

    match liquidity_parameters {
        LiquidityParameters::Ekubo(ekubo_liquidity_parameters) => {
            assert(ekubo_liquidity_parameters.quote_address == eth.contract_address, 'Bad quote address');
            assert(ekubo_liquidity_parameters.ekubo_pool_parameters.fee == fee, 'Bad ekubo fee');
            assert(ekubo_liquidity_parameters.ekubo_pool_parameters.tick_spacing == tick_spacing, 'Bad ekubo tick spacing');
            assert(ekubo_liquidity_parameters.ekubo_pool_parameters.starting_tick == starting_tick, 'Bad ekubo starting tick');
            assert(ekubo_liquidity_parameters.ekubo_pool_parameters.bound == bound, 'Bad ekubo bound');
        },
        LiquidityParameters::Jediswap(jediswap_liquidity_parameters) => panic_with_felt252('wrong liquidity parameters type'),
    }
}

#[test]
fn test_launch_memecoin_pair_exists_should_succeed() {
    // Given
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };
    let jediswap_factory = IJediswapFactoryDispatcher { contract_address: JEDI_FACTORY_ADDRESS() };

    // When a pair already exists
    jediswap_factory.create_pair(memecoin_address, eth.contract_address);

    // Then the launch should be successful

    let eth_amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    let factory_balance_meme = memecoin.balanceOf(factory.contract_address);
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(factory.contract_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(factory.contract_address), owner);
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

    assert(memecoin.is_launched(), 'should be launched');
}


#[test]
#[should_panic(expected: ('Already launched',))]
fn test_launch_memecoin_already_launched() {
    let (memecoin, memecoin_address) = deploy_and_launch_memecoin();
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };

    // Try to launch again
    // approve spending of eth by factory
    let eth_amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    let factory_balance_meme = memecoin.balanceOf(factory.contract_address);
    start_prank(CheatTarget::One(eth.contract_address), OWNER());
    eth.approve(factory.contract_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(factory.contract_address), OWNER());
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
}


#[test]
#[should_panic(expected: ('Token not deployed by factory',))]
fn test_launch_memecoin_not_unruggable_jediswap() {
    let (eth, eth_address) = deploy_eth();
    let (other_token, other_token_address) = deploy_token_from_class_at_address_with_owner(
        OWNER(), 'random'.try_into().unwrap(), eth_address
    );
    let (_, router_address) = deploy_jedi_amm_factory_and_router();
    let factory = IFactoryDispatcher { contract_address: deploy_meme_factory(router_address) };

    // Try to launch again
    // approve spending of eth by factory
    let eth_amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    let factory_balance_other_token = other_token.balanceOf(factory.contract_address);
    start_prank(CheatTarget::One(eth.contract_address), OWNER());
    eth.approve(factory.contract_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(factory.contract_address), OWNER());
    let pair_address = factory
        .launch_on_jediswap(
            LaunchParameters {
                memecoin_address: other_token_address,
                transfer_restriction_delay: TRANSFER_RESTRICTION_DELAY,
                max_percentage_buy_launch: MAX_PERCENTAGE_BUY_LAUNCH,
                quote_address: eth.contract_address,
                initial_holders: INITIAL_HOLDERS(),
                initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            },
            eth_amount,
            DEFAULT_MIN_LOCKTIME,
        );
}


#[test]
#[should_panic(expected: ('Max percentage buy too low',))]
fn test_launch_memecoin_with_percentage_buy_launch_too_low() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };

    // approve spending of eth by factory
    let eth_amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    let factory_balance_meme = memecoin.balanceOf(factory.contract_address);
    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(factory.contract_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(factory.contract_address), owner);
    let pair_address = factory
        .launch_on_jediswap(
            LaunchParameters {
                memecoin_address,
                transfer_restriction_delay: TRANSFER_RESTRICTION_DELAY,
                max_percentage_buy_launch: 49, // 0.49%
                quote_address: eth.contract_address,
                initial_holders: INITIAL_HOLDERS(),
                initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            },
            eth_amount,
            DEFAULT_MIN_LOCKTIME,
        );
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_launch_memecoin_not_owner() {
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory();
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let pair_address = factory
        .launch_on_jediswap(
            LaunchParameters {
                memecoin_address,
                transfer_restriction_delay: TRANSFER_RESTRICTION_DELAY,
                max_percentage_buy_launch: MAX_PERCENTAGE_BUY_LAUNCH,
                quote_address: ETH_ADDRESS(),
                initial_holders: INITIAL_HOLDERS(),
                initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            },
            1,
            DEFAULT_MIN_LOCKTIME,
        );
}

#[test]
#[should_panic(expected: ('Quote token is memecoin',))]
fn test_launch_memecoin_quote_memecoin_jedsiwap() {
    let owner = snforge_std::test_address();
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };

    // Create second memecoin used as quote
    start_prank(CheatTarget::One(factory.contract_address), owner);
    let quote_address = factory
        .create_memecoin(
            owner: owner,
            name: NAME(),
            symbol: SYMBOL(),
            initial_supply: DEFAULT_INITIAL_SUPPLY(),
            contract_address_salt: SALT() + 1,
        );
    stop_prank(CheatTarget::One(factory.contract_address));
    let quote = ERC20ABIDispatcher { contract_address: quote_address }; // actually a memecoin

    // Try to launch again
    // approve spending of eth by factory
    let quote_amount: u256 = 1 * pow_256(10, 18); // 1 ETHER
    let factory_balance_quote = quote.balanceOf(factory.contract_address);
    start_prank(CheatTarget::One(quote.contract_address), owner);
    quote.approve(factory.contract_address, quote_amount);
    stop_prank(CheatTarget::One(quote.contract_address));

    start_prank(CheatTarget::One(factory.contract_address), owner);
    let pair_address = factory
        .launch_on_jediswap(
            LaunchParameters {
                memecoin_address,
                transfer_restriction_delay: TRANSFER_RESTRICTION_DELAY,
                max_percentage_buy_launch: MAX_PERCENTAGE_BUY_LAUNCH,
                quote_address: quote.contract_address,
                initial_holders: INITIAL_HOLDERS(),
                initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            },
            quote_amount,
            DEFAULT_MIN_LOCKTIME,
        );
}

#[test]
#[should_panic(expected: ('Exchange address is zero',))]
//TODO: does this test still make sense?
fn test_launch_memecoin_amm_not_whitelisted() {
    //INFO: Ekubo is not supported in unit tests, as we don't have a way
    // to deploy their contracts. Thus, it's not possible to use it in unit tests.
    let owner = starknet::get_contract_address();
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };

    let pool_address = factory
        .launch_on_ekubo(
            LaunchParameters {
                memecoin_address,
                transfer_restriction_delay: TRANSFER_RESTRICTION_DELAY,
                max_percentage_buy_launch: MAX_PERCENTAGE_BUY_LAUNCH,
                quote_address: eth.contract_address,
                initial_holders: INITIAL_HOLDERS(),
                initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            },
            EkuboPoolParameters {
                fee: 0, tick_spacing: 0, starting_price: i129 { sign: false, mag: 0 }, bound: 0
            }
        );
}
