use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank, CheatTarget};
use starknet::{ContractAddress, contract_address_const};
use unruggable::exchanges::{Exchange, SupportedExchanges, ExchangeTrait};
use unruggable::factory::{IFactory, IFactoryDispatcher, IFactoryDispatcherTrait};
use unruggable::tests::utils::{
    deploy_amm_factory_and_router, deploy_meme_factory, deploy_locker, deploy_eth, OWNER, NAME,
    SYMBOL, DEFAULT_INITIAL_SUPPLY, INITIAL_HOLDERS, INITIAL_HOLDERS_AMOUNTS, SALT
};
use unruggable::tokens::interface::{
    IUnruggableMemecoin, IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

#[test]
fn test_amm_router_address() {
    let (_, router_address) = deploy_amm_factory_and_router();
    let memecoin_factory_address = deploy_meme_factory(router_address);
    let memecoin_factory = IFactoryDispatcher { contract_address: memecoin_factory_address };

    let amm_router_address = memecoin_factory
        .amm_router_address(amm_name: SupportedExchanges::JediSwap.to_string());
    assert(amm_router_address == router_address, 'wrong amm router_address');
}

#[test]
fn test_is_memecoin() {
    // Required contracts
    let (_, router_address) = deploy_amm_factory_and_router();
    let memecoin_factory_address = deploy_meme_factory(router_address);
    let memecoin_factory = IFactoryDispatcher { contract_address: memecoin_factory_address };
    let locker_address = deploy_locker();
    let (eth, eth_address) = deploy_eth();

    let eth_amount: u256 = eth.total_supply() / 2; // 50% of supply

    start_prank(CheatTarget::One(eth.contract_address), OWNER());
    eth.approve(memecoin_factory_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(memecoin_factory.contract_address), OWNER());
    let memecoin_address = memecoin_factory
        .create_memecoin(
            owner: OWNER(),
            :locker_address,
            name: NAME(),
            symbol: SYMBOL(),
            initial_supply: DEFAULT_INITIAL_SUPPLY(),
            initial_holders: INITIAL_HOLDERS(),
            initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            transfer_limit_delay: 1000,
            counterparty_token: eth,
            contract_address_salt: SALT(),
        );
    stop_prank(CheatTarget::One(memecoin_factory.contract_address));

    assert(memecoin_factory.is_memecoin(address: memecoin_address), 'should be memecoin');
    assert(
        !memecoin_factory.is_memecoin(address: 'random address'.try_into().unwrap()),
        'should not be memecoin'
    );
}


#[test]
fn test_create_memecoin() {
    // Required contracts
    let (_, router_address) = deploy_amm_factory_and_router();
    let memecoin_factory_address = deploy_meme_factory(router_address);
    let memecoin_factory = IFactoryDispatcher { contract_address: memecoin_factory_address };
    let locker_address = deploy_locker();
    let (eth, eth_address) = deploy_eth();

    let eth_amount: u256 = eth.total_supply() / 2; // 50% of supply

    start_prank(CheatTarget::One(eth.contract_address), OWNER());
    eth.approve(memecoin_factory_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(memecoin_factory.contract_address), OWNER());
    let memecoin_address = memecoin_factory
        .create_memecoin(
            owner: OWNER(),
            :locker_address,
            name: NAME(),
            symbol: SYMBOL(),
            initial_supply: DEFAULT_INITIAL_SUPPLY(),
            initial_holders: INITIAL_HOLDERS(),
            initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            transfer_limit_delay: 1000,
            counterparty_token: eth,
            contract_address_salt: SALT(),
        );
    stop_prank(CheatTarget::One(memecoin_factory.contract_address));

    let memecoin = IUnruggableMemecoinDispatcher { contract_address: memecoin_address };

    assert(memecoin.name() == NAME(), 'wrong memecoin name');
    assert(memecoin.symbol() == SYMBOL(), 'wrong memecoin symbol');
    // initial supply - initial holder balance
    let holders_sum = *INITIAL_HOLDERS_AMOUNTS()[0] + *INITIAL_HOLDERS_AMOUNTS()[1];
    assert(
        memecoin.balanceOf(memecoin_address) == DEFAULT_INITIAL_SUPPLY() - holders_sum,
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

