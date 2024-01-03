use core::traits::TryInto;
use debug::PrintTrait;
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{start_prank, stop_prank, CheatTarget, TxInfoMock};
use starknet::ContractAddress;
use unruggable::factory::interface::{IFactoryDispatcher, IFactoryDispatcherTrait};
use unruggable::tests::addresses::{JEDI_FACTORY_ADDRESS, JEDI_ROUTER_ADDRESS};
use unruggable::tests::unit_tests::utils::{
    deploy_meme_factory, deploy_locker, deploy_eth_with_owner, NAME, SYMBOL, DEFAULT_INITIAL_SUPPLY,
    INITIAL_HOLDERS, INITIAL_HOLDERS_AMOUNTS, TRANSFER_LIMIT_DELAY, SALT, DefaultTxInfoMock
};
use unruggable::tokens::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};

/// Deploys the factory and the memecoin.
/// Sends 50% of the ETH supply to the memecoin.
/// The effective price upon launch will be 1 ETH = 2 MEME
/// Given that the entire supply of MEME is LPed
fn deploy_memecoin_through_factory_with_owner(
    owner: ContractAddress
) -> (IUnruggableMemecoinDispatcher, ContractAddress) {
    let memecoin_factory_address = deploy_meme_factory(JEDI_ROUTER_ADDRESS());
    let memecoin_factory = IFactoryDispatcher { contract_address: memecoin_factory_address };
    let lock_manager_address = deploy_locker();

    // We have to deploy our own "ETH" as we cannot modify the balances of the real ETH.
    let (eth, eth_address) = deploy_eth_with_owner(owner);

    let eth_amount: u256 = eth.total_supply() / 2; // 50% of supply

    start_prank(CheatTarget::One(eth.contract_address), owner);
    eth.approve(memecoin_factory_address, eth_amount);
    stop_prank(CheatTarget::One(eth.contract_address));

    start_prank(CheatTarget::One(memecoin_factory.contract_address), owner);
    let memecoin_address = memecoin_factory
        .create_memecoin(
            owner: owner,
            :lock_manager_address,
            name: NAME(),
            symbol: SYMBOL(),
            initial_supply: DEFAULT_INITIAL_SUPPLY(),
            initial_holders: INITIAL_HOLDERS(),
            initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            transfer_limit_delay: TRANSFER_LIMIT_DELAY,
            counterparty_token: eth,
            contract_address_salt: SALT(),
        );
    stop_prank(CheatTarget::One(memecoin_factory.contract_address));

    // Upon deployment, we mock the transaction_hash of the current tx.
    // This is because for each tx, we check during transfers whether a transfer already
    // occured in the same tx. Rather than adding these lines in each test, we make it a default.
    let mut tx_info: TxInfoMock = Default::default();
    tx_info.transaction_hash = Option::Some(1234);
    snforge_std::start_spoof(CheatTarget::One(memecoin_address), tx_info);

    (IUnruggableMemecoinDispatcher { contract_address: memecoin_address }, memecoin_address)
}

fn sort_tokens(
    tokenA: ContractAddress, tokenB: ContractAddress
) -> (ContractAddress, ContractAddress) {
    let tokenA: felt252 = tokenA.into();
    let tokenB: felt252 = tokenB.into();
    let tokenA: u256 = tokenA.into();
    let tokenB: u256 = tokenB.into();
    if tokenA < tokenB {
        let token0: felt252 = tokenA.try_into().unwrap();
        let token1: felt252 = tokenB.try_into().unwrap();
        (token0.try_into().unwrap(), token1.try_into().unwrap())
    } else {
        let token0: felt252 = tokenB.try_into().unwrap();
        let token1: felt252 = tokenA.try_into().unwrap();
        (token0.try_into().unwrap(), token1.try_into().unwrap())
    }
}
