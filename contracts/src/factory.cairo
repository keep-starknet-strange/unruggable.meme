mod factory;
mod interface;
use factory::Factory;

use interface::{IFactory, IFactoryDispatcher, IFactoryDispatcherTrait};

#[derive(Copy, Drop, Serde)]
struct LaunchParameters {
    memecoin_address: starknet::ContractAddress,
    transfer_restriction_delay: u64,
    max_percentage_buy_launch: u16,
    quote_address: starknet::ContractAddress,
}
