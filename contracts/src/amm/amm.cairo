use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, starknet::Store)]
struct AMM {
    name: felt252,
    router_address: ContractAddress
}

#[derive(Drop, Copy, Serde)]
enum AMMV2 {
    JediSwap,
}

impl AMMIntoFelt252 of Into<AMMV2, felt252> {
    fn into(self: AMMV2) -> felt252 {
        match self {
            AMMV2::JediSwap => 'JediSwap'
        }
    }
}
