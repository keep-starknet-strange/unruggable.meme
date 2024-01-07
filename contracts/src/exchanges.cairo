mod ekubo;

mod jediswap_adapter;
use ekubo::ekubo_adapter;
use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, Hash)]
enum SupportedExchanges {
    Jediswap,
    Ekubo
}

trait ExchangeAdapter<A, R> {
    fn create_and_add_liquidity(
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        counterparty_address: ContractAddress,
        additional_parameters: A,
    ) -> R;
}
