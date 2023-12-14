use starknet::ContractAddress;

#[derive(Drop, Copy, Serde)]
struct AMMRouter {
    name: felt252,
    address: ContractAddress
}

#[derive(Drop, Copy, Serde)]
enum AMM {
    JediSwap,
}

impl AMMIntoFelt252 of Into<AMM, felt252> {
    fn into(self: AMM) -> felt252 {
        match self {
            AMM::JediSwap => 'JediSwap'
        }
    }
}

#[derive(Drop, Copy, Serde)]
enum Network {
    Mainnet,
    Goerli,
    Sepolia,
    Local,
}

impl Felt252TryIntoNetwork of TryInto<felt252, Network> {
    fn try_into(self: felt252) -> Option<Network> {
        // TODO: Validate names
        if self == 'MAINNET' {
            Option::Some(Network::Mainnet)
        } else if self == 'SN_GOERLI' {
            Option::Some(Network::Goerli)
        } else if self == 'SEPOLIA' {
            Option::Some(Network::Sepolia)
        } else if self == 'LOCAL' {
            Option::Some(Network::Local)
        } else {
            Option::None(())
        }
    }
}
