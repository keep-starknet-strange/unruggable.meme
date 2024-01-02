mod ekubo_adapter;

mod jediswap_adapter;
use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, starknet::Store)]
struct Exchange {
    name: felt252,
    contract_address: ContractAddress
}

#[derive(Drop, Copy, Serde)]
enum SupportedExchanges {
    JediSwap,
    Ekubo //TODO: Not yet implemented
}

#[generate_trait]
impl ExchangeImpl of ExchangeTrait {
    fn to_string(self: SupportedExchanges) -> felt252 {
        match self {
            SupportedExchanges::JediSwap => 'JediSwap',
            SupportedExchanges::Ekubo => 'Ekubo'
        }
    }
}


trait IAmmAdapter<TContractState> {
    fn create_and_add_liquidity(
        ref self: TContractState,
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        counterparty_address: ContractAddress,
        additional_parameters: Span<felt252>,
    ) -> ContractAddress;
}
