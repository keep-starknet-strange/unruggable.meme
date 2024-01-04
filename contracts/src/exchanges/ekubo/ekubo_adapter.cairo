use array::ArrayTrait;
use core::option::OptionTrait;
use core::traits::TryInto;
use debug::PrintTrait;
use openzeppelin::access::ownable::OwnableComponent;
use openzeppelin::token::erc20::ERC20Component;
use openzeppelin::token::erc20::interface::IERC20CamelOnly;
use openzeppelin::token::erc20::interface::IERC20Dispatcher;
use openzeppelin::token::erc20::interface::{
    IERC20, IERC20Metadata, ERC20ABIDispatcher, ERC20ABIDispatcherTrait
};
use starknet::{get_block_timestamp, get_contract_address, ContractAddress, ClassHash};
use unruggable::errors;
use unruggable::exchanges::ekubo::launcher::{
    IEkuboLauncherDispatcher, IEkuboLauncherDispatcherTrait,
};
use unruggable::locker::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::tokens::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait, IUnruggableAdditional,
    IUnruggableMemecoinCamel, IUnruggableMemecoinSnake
};
use unruggable::utils::math::PercentageMath;


#[derive(Copy, Drop, Serde)]
struct EkuboLaunchParameters {
    token_address: ContractAddress,
    counterparty_address: ContractAddress,
    fee: u128,
    tick_spacing: u128,
    // the sign of the starting tick and the boudns is determined by the address of the deployed token contract
    starting_tick: u128,
    // The LP providing bound, upper/lower determined by the address of the LPed tokens
    bound: u128,
}

struct EkuboAdditionalParameters {
    fee: u128,
    tick_spacing: u128,
    // the sign of the starting tick and the boudns is determined by the address of the deployed token contract
    starting_tick: u128,
    // The LP providing bound, upper/lower determined by the address of the LPed tokens
    bound: u128,
}

#[storage]
struct Storage {}


impl EkuboAdapterImpl of unruggable::exchanges::IAmmAdapter<EkuboAdditionalParameters, u64> {
    fn create_and_add_liquidity(
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        counterparty_address: ContractAddress,
        additional_parameters: EkuboAdditionalParameters,
    ) -> u64 {
        let ekubo_launch_params = EkuboLaunchParameters {
            token_address: token_address,
            counterparty_address: counterparty_address,
            fee: additional_parameters.fee,
            tick_spacing: additional_parameters.tick_spacing,
            starting_tick: additional_parameters.starting_tick,
            bound: additional_parameters.bound,
        };

        let memecoin = IUnruggableMemecoinDispatcher { contract_address: token_address, };
        let this_address = get_contract_address();
        let memecoin_address = memecoin.contract_address;
        let counterparty_token = ERC20ABIDispatcher { contract_address: counterparty_address, };
        let caller_address = starknet::get_caller_address();

        let ekubo_launchpad = IEkuboLauncherDispatcher { contract_address: exchange_address };
        assert(ekubo_launchpad.contract_address.is_non_zero(), errors::EXCHANGE_ADDRESS_ZERO);

        // Transfer the tokens to the launchpad contract.
        let memecoin_balance = memecoin.balance_of(this_address);
        memecoin.transfer(ekubo_launchpad.contract_address, memecoin_balance);

        let nft_id = ekubo_launchpad.launch_token(ekubo_launch_params);
        //TODO: handle the NFT representing the LP

        // Ensure that the LPing operation has not returned more than 0.5% of the provided liquidity to the caller.
        // Otherwise, there was an error in the LP parameters.
        let total_supply = memecoin.total_supply();
        let team_alloc = memecoin.get_team_allocation();
        let max_returned_tokens = PercentageMath::percent_mul(total_supply - team_alloc, 9950);
        assert(memecoin.balanceOf(this_address) < max_returned_tokens, 'ekubo has returned tokens');

        // Any counterparty tokens that were deposited in this contract must be returned to the caller
        // as no counterparty is required to launch a memecoin with Ekubo.
        clear(counterparty_address);
        assert(counterparty_token.balanceOf(this_address) == 0, 'counterparty leftovers');

        //TODO: lock tokens
        nft_id
    }
}

fn clear(token: ContractAddress) {
    let caller = starknet::get_caller_address();
    let this = starknet::get_contract_address();
    let token = ERC20ABIDispatcher { contract_address: token, };
    token.transfer(caller, token.balanceOf(this));
}
