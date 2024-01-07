use ekubo::types::i129::i129;
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, start_warp, stop_warp
};
use starknet::{ContractAddress, contract_address_const};
use unruggable::exchanges::ekubo_adapter::EkuboPoolParameters;
use unruggable::exchanges::jediswap_adapter::{
    IJediswapFactory, IJediswapFactoryDispatcher, IJediswapFactoryDispatcherTrait, IJediswapRouter,
    IJediswapRouterDispatcher, IJediswapRouterDispatcherTrait, IJediswapPairDispatcher,
    IJediswapPairDispatcherTrait
};
use unruggable::exchanges::{SupportedExchanges};
use unruggable::factory::{IFactory, IFactoryDispatcher, IFactoryDispatcherTrait};
use unruggable::locker::interface::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::locker::{LockPosition};
use unruggable::tests::addresses::{ETH_ADDRESS};
use unruggable::tests::unit_tests::utils::{
    deploy_jedi_amm_factory_and_router, deploy_meme_factory, deploy_locker, deploy_eth, OWNER, NAME,
    SYMBOL, DEFAULT_INITIAL_SUPPLY, INITIAL_HOLDERS, INITIAL_HOLDERS_AMOUNTS, SALT,
    deploy_memecoin_through_factory, MEMEFACTORY_ADDRESS,
    deploy_memecoin_through_factory_with_owner, pow_256, LOCK_MANAGER_ADDRESS, DEFAULT_MIN_LOCKTIME,
    deploy_and_launch_memecoin
};
use unruggable::tokens::interface::{
    IUnruggableMemecoin, IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

#[test]
fn test_lock_manager_address() {
    let (_, router_address) = deploy_jedi_amm_factory_and_router();
    let memecoin_factory_address = deploy_meme_factory(router_address);
    let memecoin_factory = IFactoryDispatcher { contract_address: memecoin_factory_address };

    let lock_manager_address = memecoin_factory.lock_manager_address();
    assert(lock_manager_address == LOCK_MANAGER_ADDRESS(), 'wrong lock manager address');
}

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
            initial_holders: INITIAL_HOLDERS(),
            initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            transfer_limit_delay: 1000,
            contract_address_salt: SALT(),
        );
    stop_prank(CheatTarget::One(memecoin_factory.contract_address));

    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

    assert(memecoin.name() == NAME(), 'wrong memecoin name');
    assert(memecoin.symbol() == SYMBOL(), 'wrong memecoin symbol');
    // initial supply - initial holder balance
    let holders_sum = *INITIAL_HOLDERS_AMOUNTS()[0] + *INITIAL_HOLDERS_AMOUNTS()[1];
    assert(
        memecoin.balanceOf(memecoin_factory_address) == DEFAULT_INITIAL_SUPPLY() - holders_sum,
        'wrong initial supply'
    );
    assert(
        memecoin.balanceOf(*INITIAL_HOLDERS()[0]) == *INITIAL_HOLDERS_AMOUNTS()[0],
        'wrong initial_holder_1 balance'
    );
    assert(
        memecoin.balanceOf(*INITIAL_HOLDERS()[1]) == *INITIAL_HOLDERS_AMOUNTS()[1],
        'wrong initial_holder_2 balance'
    );
}

#[test]
fn test_launch_memecoin_happy_path() {
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
    start_warp(CheatTarget::One(memecoin_address), 1);
    let pair_address = factory
        .launch_on_jediswap(
            memecoin_address, eth.contract_address, eth_amount, DEFAULT_MIN_LOCKTIME,
        );
    stop_prank(CheatTarget::One(factory.contract_address));
    stop_warp(CheatTarget::One(memecoin_address));

    assert(memecoin.is_launched(), 'should be launched');

    // Check pair creation
    let pair = IJediswapPairDispatcher { contract_address: pair_address };
    let (token_0_reserves, token_1_reserves, _) = pair.get_reserves();
    assert(pair.token0() == memecoin_address, 'wrong token 0 address');
    assert(pair.token1() == eth.contract_address, 'wrong token 1 address');
    assert(token_0_reserves == factory_balance_meme, 'wrong pool token reserves');
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
            memecoin_address, eth.contract_address, eth_amount, DEFAULT_MIN_LOCKTIME,
        );
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_launch_memecoin_not_owner() {
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory();
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let pair_address = factory
        .launch_on_jediswap(memecoin_address, ETH_ADDRESS(), 1, DEFAULT_MIN_LOCKTIME,);
}

#[test]
#[should_panic(expected: ('Exchange address is zero',))]
//TODO: does this still make sense?
fn test_launch_memecoin_amm_not_whitelisted() {
    //INFO: Ekubo is not supported in unit tests, as we don't have a way
    // to deploy their contracts. Thus, it's not possible to use it in unit tests.
    let owner = starknet::get_contract_address();
    let factory = IFactoryDispatcher { contract_address: MEMEFACTORY_ADDRESS() };
    let (memecoin, memecoin_address) = deploy_memecoin_through_factory_with_owner(owner);
    let eth = ERC20ABIDispatcher { contract_address: ETH_ADDRESS() };

    let pool_address = factory
        .launch_on_ekubo(
            memecoin_address,
            eth.contract_address,
            EkuboPoolParameters {
                fee: 0, tick_spacing: 0, starting_tick: i129 { sign: false, mag: 0 }, bound: 0
            }
        );
}
