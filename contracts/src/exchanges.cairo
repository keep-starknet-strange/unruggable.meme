mod ekubo;

mod jediswap_adapter;
mod starkdefi;
use ekubo::ekubo_adapter;
use starkdefi::starkdefi_adapter;
use starknet::ContractAddress;

#[derive(Drop, Copy, Serde, Hash)]
enum SupportedExchanges {
    Jediswap,
    Ekubo,
    Starkdefi,
}

trait ExchangeAdapter<A, R> {
    fn create_and_add_liquidity(
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        quote_address: ContractAddress,
        additional_parameters: A,
    ) -> R;
}
