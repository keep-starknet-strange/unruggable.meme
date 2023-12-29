use core::traits::TryInto;
use openzeppelin::token::erc20::interface::ERC20ABIDispatcher;
use openzeppelin::token::erc20::interface::ERC20ABIDispatcherTrait;
use snforge_std::{ContractClass, ContractClassTrait, CheatTarget, declare, start_prank, stop_prank};
use starknet::ContractAddress;
use unruggable::amm::amm::{AMM, AMMV2, AMMTrait};
use unruggable::tokens::factory::{
    IUnruggableMemecoinFactoryDispatcher, IUnruggableMemecoinFactoryDispatcherTrait
};

// Constants
fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

fn NAME() -> felt252 {
    'name'.try_into().unwrap()
}

fn SYMBOL() -> felt252 {
    'symbol'.try_into().unwrap()
}

fn INITIAL_HOLDER_1() -> ContractAddress {
    'initial_holder_1'.try_into().unwrap()
}

fn INITIAL_HOLDER_2() -> ContractAddress {
    'initial_holder_2'.try_into().unwrap()
}


fn INITIAL_HOLDERS() -> Span<ContractAddress> {
    array![INITIAL_HOLDER_1(), INITIAL_HOLDER_2()].span()
}

fn INITIAL_HOLDERS_AMOUNTS() -> Span<u256> {
    array![50, 50].span()
}

fn DEPLOYER() -> ContractAddress {
    'deployer'.try_into().unwrap()
}

fn SALT() -> felt252 {
    'salty'.try_into().unwrap()
}

fn ETH_ADDRESS() -> ContractAddress {
    0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7.try_into().unwrap()
}

// Deployments

// AMM

fn deploy_amm_factory() -> ContractAddress {
    let pair_class = declare('PairC1');

    let mut constructor_calldata = Default::default();

    Serde::serialize(@pair_class.class_hash, ref constructor_calldata);
    Serde::serialize(@DEPLOYER(), ref constructor_calldata);
    let factory_class = declare('FactoryC1');

    let factory_address = factory_class.deploy(@constructor_calldata).unwrap();

    factory_address
}

fn deploy_router(factory_address: ContractAddress) -> ContractAddress {
    let amm_router_class = declare('RouterC1');

    let mut router_constructor_calldata = Default::default();
    Serde::serialize(@factory_address, ref router_constructor_calldata);

    let amm_router_address = amm_router_class.deploy(@router_constructor_calldata).unwrap();

    amm_router_address
}

fn deploy_amm_factory_and_router() -> (ContractAddress, ContractAddress) {
    let amm_factory_address = deploy_amm_factory();
    let amm_router_address = deploy_router(amm_factory_address);

    (amm_factory_address, amm_router_address)
}

// MemeFactory
fn deploy_meme_factory(router_address: ContractAddress) -> ContractAddress {
    let memecoin_class_hash = declare('UnruggableMemecoin').class_hash;

    // Declare availables AMMs for this factory
    let mut amms = array![AMM { name: AMMV2::JediSwap.to_string(), router_address }];

    let contract = declare('UnruggableMemecoinFactory');
    let mut calldata = array![];
    Serde::serialize(@OWNER(), ref calldata);
    Serde::serialize(@memecoin_class_hash, ref calldata);
    Serde::serialize(@amms.into(), ref calldata);
    contract.deploy(@calldata).expect('UnrugFactory deployment failed')
}

fn deploy_meme_factory_with_owner(
    owner: ContractAddress, router_address: ContractAddress
) -> ContractAddress {
    let memecoin_class_hash = declare('UnruggableMemecoin').class_hash;

    // Declare availables AMMs for this factory
    let mut amms = array![AMM { name: AMMV2::JediSwap.to_string(), router_address }];

    let contract = declare('UnruggableMemecoinFactory');
    let mut calldata = array![];
    Serde::serialize(@owner, ref calldata);
    Serde::serialize(@memecoin_class_hash, ref calldata);
    Serde::serialize(@amms.into(), ref calldata);
    contract.deploy(@calldata).expect('UnrugFactory deployment failed')
}

// Locker

fn deploy_locker() -> ContractAddress {
    let locker_calldata = array![200];
    let locker_contract = declare('TokenLocker');
    locker_contract.deploy(@locker_calldata).expect('Locker deployment failed')
}

// ETH Token

const ETH_DECIMALS: u8 = 18;

fn ETH_INITIAL_SUPPLY() -> u256 {
    2 * pow_256(10, ETH_DECIMALS)
}

fn deploy_eth() -> (ERC20ABIDispatcher, ContractAddress) {
    deploy_eth_with_owner(OWNER())
}

fn deploy_eth_with_owner(owner: ContractAddress) -> (ERC20ABIDispatcher, ContractAddress) {
    let token = declare('ERC20Token');
    let mut calldata = Default::default();
    Serde::serialize(@ETH_INITIAL_SUPPLY(), ref calldata);
    Serde::serialize(@owner, ref calldata);

    let address = token.deploy_at(@calldata, ETH_ADDRESS()).unwrap();
    let dispatcher = ERC20ABIDispatcher { contract_address: address, };
    (dispatcher, address)
}

// Memercoin

fn deploy_memecoin() -> ContractAddress {
    // Required contracts
    let (_, router_address) = deploy_amm_factory_and_router();
    let memecoin_factory_address = deploy_meme_factory(router_address);
    let memecoin_factory = IUnruggableMemecoinFactoryDispatcher {
        contract_address: memecoin_factory_address
    };
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
            initial_supply: ETH_INITIAL_SUPPLY(),
            initial_holders: INITIAL_HOLDERS(),
            initial_holders_amounts: INITIAL_HOLDERS_AMOUNTS(),
            eth_contract: eth,
            contract_address_salt: SALT(),
        );
    stop_prank(CheatTarget::One(memecoin_factory.contract_address));
    memecoin_address
}

// Math
fn pow_256(self: u256, mut exponent: u8) -> u256 {
    if self.is_zero() {
        return 0;
    }
    let mut result = 1;
    let mut base = self;

    loop {
        if exponent & 1 == 1 {
            result = result * base;
        }

        exponent = exponent / 2;
        if exponent == 0 {
            break result;
        }

        base = base * base;
    }
}

