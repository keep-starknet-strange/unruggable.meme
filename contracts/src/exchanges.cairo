mod ekubo;

mod jediswap_adapter;
use ekubo::ekubo_adapter;
use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, Hash)]
enum SupportedExchanges {
    Jediswap,
    Ekubo
}

trait IAmmAdapter<TContractState, A, R> {
    fn create_and_add_liquidity(
        ref self: TContractState,
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        counterparty_address: ContractAddress,
        unlock_time: u64,
        additional_parameters: A,
    ) -> R;
}
