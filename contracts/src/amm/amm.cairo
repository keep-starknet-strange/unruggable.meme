use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, starknet::Store)]
struct AMM {
    name: felt252,
    router_address: ContractAddress
}

#[derive(Drop, Copy, Serde)]
enum AMMV2 {
    JediSwap,
    Ekubo // Unsupported
}

#[generate_trait]
impl AMMImpl of AMMTrait {
    fn to_string(self: AMMV2) -> felt252 {
        match self {
            AMMV2::JediSwap => 'JediSwap',
            AMMV2::Ekubo => 'Ekubo'
        }
    }
}

