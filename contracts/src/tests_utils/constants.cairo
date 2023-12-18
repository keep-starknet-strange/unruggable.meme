use starknet::ContractAddress;

const TOKEN_MULTIPLIER: u256 = 1000000000000000000;
const TOKEN0_NAME: felt252 = 'TOKEN0';
const TOKEN1_NAME: felt252 = 'TOKEN1';
const TOKEN2_NAME: felt252 = 'TOKEN2';
const SYMBOL: felt252 = 'SYMBOL';
const MINIMUM_LIQUIDITY: u256 = 1000;

fn DEPLOYER() -> ContractAddress {
    'DEPLOYER'.try_into().unwrap()
}

fn TOKEN_0() -> ContractAddress {
    TOKEN0_NAME.try_into().unwrap()
}

fn TOKEN_1() -> ContractAddress {
    TOKEN1_NAME.try_into().unwrap()
}

fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}
