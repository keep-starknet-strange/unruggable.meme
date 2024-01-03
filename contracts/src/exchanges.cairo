mod ekubo;

mod jediswap_adapter;
use ekubo::ekubo_adapter;
use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, Hash)]
enum SupportedExchanges {
    JediSwap,
    Ekubo
}

trait IAmmAdapter<TContractState> {
    fn create_and_add_liquidity(
        ref self: TContractState,
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        counterparty_address: ContractAddress,
        unlock_time: u64,
        additional_parameters: Span<felt252>,
    ) -> Span<felt252>;
}
