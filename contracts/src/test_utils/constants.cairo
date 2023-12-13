use starknet::{ContractAddress, contract_address_try_from_felt252};

const TOKEN_MULTIPLIER: u256 = 1000000000000000000;
const TOKEN0_NAME: felt252 = 'TOKEN0';
const TOKEN1_NAME: felt252 = 'TOKEN1';
const TOKEN2_NAME: felt252 = 'TOKEN2';
const SYMBOL: felt252 = 'SYMBOL';
const MINIMUM_LIQUIDITY: u256 = 1000;

fn DEPLOYER() -> ContractAddress {
    contract_address_try_from_felt252('DEPLOYER').unwrap()
}

fn TOKEN_0() -> ContractAddress {
    contract_address_try_from_felt252(TOKEN0_NAME).unwrap()
}

fn TOKEN_1() -> ContractAddress {
    contract_address_try_from_felt252(TOKEN1_NAME).unwrap()
}

fn OWNER() -> ContractAddress {
    contract_address_try_from_felt252('OWNER').unwrap()
}
