mod ekubo_adapter;

mod jediswap_adapter;
use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, Hash)]
enum SupportedExchanges {
    JediSwap,
    Ekubo, //TODO: Not yet implemented
}

#[generate_trait]
impl ExchangeImpl of ExchangeTrait {
    fn to_string(self: SupportedExchanges) -> felt252 {
        match self {
            SupportedExchanges::JediSwap => 'Jediswap',
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
        unlock_time: u64,
        additional_parameters: Span<felt252>,
    ) -> ContractAddress;
}
