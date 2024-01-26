use array::ArrayTrait;
use core::option::OptionTrait;
use core::traits::TryInto;
use debug::PrintTrait;
use ekubo::types::i129::i129;
use openzeppelin::token::erc20::interface::{
    IERC20, IERC20Metadata, ERC20ABIDispatcher, ERC20ABIDispatcherTrait
};
use starknet::{get_contract_address, ContractAddress, ClassHash};
use unruggable::errors;
use unruggable::exchanges::ekubo::launcher::{
    IEkuboLauncherDispatcher, IEkuboLauncherDispatcherTrait, EkuboLP
};
use unruggable::token::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait,
};
use unruggable::utils::math::PercentageMath;


#[derive(Copy, Drop, Serde)]
struct EkuboLaunchParameters {
    owner: ContractAddress,
    token_address: ContractAddress,
    quote_address: ContractAddress,
    pool_params: EkuboPoolParameters
}

#[derive(Drop, Copy, Serde)]
struct EkuboPoolParameters {
    fee: u128,
    tick_spacing: u128,
    // the sign of the starting tick is positive (false) if quote/token < 1 and negative (true) otherwise
    starting_tick: i129,
    // The LP providing bound, upper/lower determined by the address of the LPed tokens
    bound: u128,
}

impl EkuboAdapterImpl of unruggable::exchanges::ExchangeAdapter<
    EkuboPoolParameters, (u64, EkuboLP)
> {
    fn create_and_add_liquidity(
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        quote_address: ContractAddress,
        additional_parameters: EkuboPoolParameters,
    ) -> (u64, EkuboLP) {
        let ekubo_launch_params = EkuboLaunchParameters {
            owner: starknet::get_caller_address(),
            token_address: token_address,
            quote_address: quote_address,
            pool_params: EkuboPoolParameters {
                fee: additional_parameters.fee,
                tick_spacing: additional_parameters.tick_spacing,
                starting_tick: additional_parameters.starting_tick,
                bound: additional_parameters.bound,
            }
        };

        let this = get_contract_address();
        let memecoin = IUnruggableMemecoinDispatcher { contract_address: token_address, };
        let memecoin_address = memecoin.contract_address;
        let quote_token = ERC20ABIDispatcher { contract_address: quote_address, };

        let ekubo_launchpad = IEkuboLauncherDispatcher { contract_address: exchange_address };
        assert(ekubo_launchpad.contract_address.is_non_zero(), errors::EXCHANGE_ADDRESS_ZERO);

        // Transfer the tokens to the launchpad contract.
        let memecoin_balance = memecoin.balance_of(this);
        memecoin.transfer(ekubo_launchpad.contract_address, memecoin_balance);

        let (id, position) = ekubo_launchpad.launch_token(ekubo_launch_params);

        // Ensure that the LPing operation has not returned more than 0.5% of the provided liquidity to the caller.
        // Otherwise, there was an error in the LP parameters.
        let total_supply = memecoin.total_supply();
        let team_alloc = memecoin.get_team_allocation();
        let max_returned_tokens = PercentageMath::percent_mul(total_supply - team_alloc, 9950);
        assert(memecoin.balanceOf(this) < max_returned_tokens, 'ekubo has returned tokens');

        (id, position)
    }
}