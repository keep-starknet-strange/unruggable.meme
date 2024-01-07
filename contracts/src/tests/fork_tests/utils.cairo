use core::traits::TryInto;
use debug::PrintTrait;
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, CheatTarget, TxInfoMock, get_class_hash,
    ContractClass
};
use starknet::ContractAddress;
use unruggable::exchanges::SupportedExchanges;
use unruggable::factory::interface::{IFactoryDispatcher, IFactoryDispatcherTrait};
use unruggable::tests::addresses::{
    JEDI_FACTORY_ADDRESS, JEDI_ROUTER_ADDRESS, EKUBO_CORE, EKUBO_POSITIONS, EKUBO_REGISTRY,
    EKUBO_NFT_CLASS_HASH, ETH_ADDRESS
};
use unruggable::tests::unit_tests::utils::{
    deploy_locker, deploy_eth_with_owner, NAME, SYMBOL, DEFAULT_INITIAL_SUPPLY, INITIAL_HOLDERS,
    INITIAL_HOLDERS_AMOUNTS, TRANSFER_LIMIT_DELAY, SALT, DefaultTxInfoMock, OWNER, TOKEN0_ADDRESS,
    MEMEFACTORY_ADDRESS
};
use unruggable::tokens::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait
};


fn EKUBO_LAUNCHER_ADDRESS() -> ContractAddress {
    'ekubo_launchpad'.try_into().unwrap()
}

fn EKUBO_SWAPPER_ADDRESS() -> ContractAddress {
    0x07a83729aaaae6344d6fca558614cd22ecdd3f5cd90ec0cd20c8d6bf08170431.try_into().unwrap()
}


// Counterparty token ensured to be token0

fn deploy_token0_with_owner(owner: ContractAddress) -> (ERC20ABIDispatcher, ContractAddress) {
    let token = declare('ERC20Token');
    let mut calldata = Default::default();
    Serde::serialize(@DEFAULT_INITIAL_SUPPLY(), ref calldata);
    Serde::serialize(@owner, ref calldata);

    let address = token.deploy_at(@calldata, TOKEN0_ADDRESS()).unwrap();
    let dispatcher = ERC20ABIDispatcher { contract_address: address, };
    (dispatcher, address)
}


fn deploy_token0() -> (ERC20ABIDispatcher, ContractAddress) {
    deploy_token0_with_owner(OWNER())
}


fn deploy_ekubo_launcher() -> ContractAddress {
    let launcher = declare('EkuboLauncher');
    let mut calldata = Default::default();
    Serde::serialize(@EKUBO_CORE(), ref calldata);
    Serde::serialize(@EKUBO_REGISTRY(), ref calldata);
    Serde::serialize(@EKUBO_POSITIONS(), ref calldata);

    launcher
        .deploy_at(@calldata, EKUBO_LAUNCHER_ADDRESS())
        .expect('EkuboLauncher deployment failed')
}

// MemeFactory
fn deploy_meme_factory(amms: Span<(SupportedExchanges, ContractAddress)>) -> ContractAddress {
    deploy_meme_factory_with_owner(OWNER(), amms)
}

fn deploy_meme_factory_with_owner(
    owner: ContractAddress, amms: Span<(SupportedExchanges, ContractAddress)>
) -> ContractAddress {
    let memecoin_class_hash = declare('UnruggableMemecoin').class_hash;
    let lock_manager_address = deploy_locker();

    let contract = declare('Factory');
    let mut calldata = array![];
    Serde::serialize(@owner, ref calldata);
    Serde::serialize(@memecoin_class_hash, ref calldata);
    Serde::serialize(@lock_manager_address, ref calldata);
    Serde::serialize(@amms.into(), ref calldata);
    contract.deploy_at(@calldata, MEMEFACTORY_ADDRESS()).expect('UnrugFactory deployment failed')
}

/// Deploys the factory and the memecoin.
/// Sends 50% of the ETH supply to the memecoin.
/// The effective price upon launch will be 1 ETH = 2 MEME
/// Given that the entire supply of MEME is LPed
//! Warning: Since these tests support ekubo, the deployment of the meme factory is done with support for ekubo
//! and we shoulnd't use the function from the unit tests.
fn deploy_memecoin_through_factory_with_owner(
    owner: ContractAddress
) -> (IUnruggableMemecoinDispatcher, ContractAddress) {
    let ekubo_launchpad = deploy_ekubo_launcher();
    let supported_amms = array![
        (SupportedExchanges::Jediswap, JEDI_ROUTER_ADDRESS()),
        (SupportedExchanges::Ekubo, ekubo_launchpad)
    ]
        .span();
    let memecoin_factory_address = deploy_meme_factory(supported_amms);
    let memecoin_factory = IFactoryDispatcher { contract_address: memecoin_factory_address };

    start_prank(CheatTarget::One(memecoin_factory.contract_address), owner);
    let memecoin_address = memecoin_factory
        .create_memecoin(
            owner: owner,
            name: NAME(),
            symbol: SYMBOL(),
            initial_supply: DEFAULT_INITIAL_SUPPLY(),
            initial_holders: INITIAL_HOLDERS(),
            initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            transfer_limit_delay: TRANSFER_LIMIT_DELAY,
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
