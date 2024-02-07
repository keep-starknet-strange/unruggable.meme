use array::ArrayTrait;
use debug::PrintTrait;
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use starknet::{get_block_timestamp, ContractAddress, get_contract_address, get_caller_address};
use unruggable::errors;

use unruggable::exchanges::starkdefi::interfaces::{
    IStarkDRouterDispatcher, IStarkDRouterDispatcherTrait, IStarkDFactoryDispatcher,
    IStarkDFactoryDispatcherTrait, StarkDeFiAdditionalParameters
};
use unruggable::locker::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::token::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait,
};

impl StarkDeFiAdapterImpl of unruggable::exchanges::ExchangeAdapter<
    StarkDeFiAdditionalParameters, (ContractAddress, ContractAddress)
> {
    fn create_and_add_liquidity(
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        quote_address: ContractAddress,
        lp_supply: u256,
        additional_parameters: StarkDeFiAdditionalParameters,
    ) -> (ContractAddress, ContractAddress) {
        let StarkDeFiAdditionalParameters{lock_manager_address, unlock_time, quote_amount, } =
            additional_parameters;
        let memecoin = IUnruggableMemecoinDispatcher { contract_address: token_address, };
        let this = get_contract_address();
        let memecoin_address = memecoin.contract_address;
        let quote_token = ERC20ABIDispatcher { contract_address: quote_address, };
        let caller_address = starknet::get_caller_address();

        // Create liquidity pool
        let stable = false;
        let fee = 100; // 1%
        let starkdefi_router = IStarkDRouterDispatcher { contract_address: exchange_address };
        assert(starkdefi_router.contract_address.is_non_zero(), errors::EXCHANGE_ADDRESS_ZERO);
        let starkdefi_factory = IStarkDFactoryDispatcher {
            contract_address: starkdefi_router.factory(),
        };

        // Add liquidity
        quote_token.transferFrom(caller_address, this, quote_amount,);
        memecoin.approve(starkdefi_router.contract_address, lp_supply);
        quote_token.approve(starkdefi_router.contract_address, quote_amount);

        //
        let (amount_memecoin, amount_eth, liquidity_received) = starkdefi_router
            .add_liquidity(
                memecoin_address,
                quote_address,
                stable,
                fee,
                lp_supply,
                quote_amount,
                lp_supply,
                quote_amount,
                this, // locked
                deadline: get_block_timestamp()
            );
        let pair_address = starkdefi_factory.get_pair(memecoin_address, quote_address, stable, fee);
        let pair = ERC20ABIDispatcher { contract_address: pair_address, };

        // Lock LP tokens
        let lock_manager = ILockManagerDispatcher { contract_address: lock_manager_address };
        pair.approve(lock_manager_address, liquidity_received);
        let lock_position = lock_manager
            .lock_tokens(
                token: pair_address,
                amount: liquidity_received,
                unlock_time: unlock_time,
                withdrawer: caller_address,
            );

        (pair.contract_address, lock_position)
    }
}
