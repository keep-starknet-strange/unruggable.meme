use array::ArrayTrait;
use debug::PrintTrait;
use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
use starknet::{get_block_timestamp, ContractAddress, get_contract_address, get_caller_address};
use unruggable::errors;
use unruggable::locker::{ILockManagerDispatcher, ILockManagerDispatcherTrait};
use unruggable::token::interface::{
    IUnruggableMemecoinDispatcher, IUnruggableMemecoinDispatcherTrait,
};

#[starknet::interface]
trait IJediswapRouter<T> {
    fn factory(self: @T) -> ContractAddress;
    fn sort_tokens(
        self: @T, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> (ContractAddress, ContractAddress);
    fn add_liquidity(
        ref self: T,
        tokenA: ContractAddress,
        tokenB: ContractAddress,
        amountADesired: u256,
        amountBDesired: u256,
        amountAMin: u256,
        amountBMin: u256,
        to: ContractAddress,
        deadline: u64
    ) -> (u256, u256, u256);
    fn swap_exact_tokens_for_tokens(
        ref self: T,
        amountIn: u256,
        amountOutMin: u256,
        path: Array::<ContractAddress>,
        to: ContractAddress,
        deadline: u64
    ) -> Array<u256>;
}

#[starknet::interface]
trait IJediswapFactory<TContractState> {
    fn get_pair(
        self: @TContractState, token0: ContractAddress, token1: ContractAddress
    ) -> ContractAddress;
    fn create_pair(
        ref self: TContractState, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> ContractAddress;
}

#[starknet::interface]
trait IJediswapPair<T> {
    fn token0(self: @T) -> ContractAddress;
    fn token1(self: @T) -> ContractAddress;
    fn get_reserves(self: @T) -> (u256, u256, u64);
    fn mint(ref self: T, to: ContractAddress) -> u256;
    fn totalSupply(self: @T) -> u256;
}

#[derive(Copy, Drop)]
struct JediswapAdditionalParameters {
    lock_manager_address: ContractAddress,
    unlock_time: u64,
    quote_amount: u256
}

impl JediswapAdapterImpl of unruggable::exchanges::ExchangeAdapter<
    JediswapAdditionalParameters, ContractAddress
> {
    fn create_and_add_liquidity(
        exchange_address: ContractAddress,
        token_address: ContractAddress,
        quote_address: ContractAddress,
        lp_supply: u256,
        additional_parameters: JediswapAdditionalParameters,
    ) -> ContractAddress {
        let JediswapAdditionalParameters{lock_manager_address, unlock_time, quote_amount, } =
            additional_parameters;
        let memecoin = IUnruggableMemecoinDispatcher { contract_address: token_address, };
        let this = get_contract_address();
        let memecoin_address = memecoin.contract_address;
        let quote_token = ERC20ABIDispatcher { contract_address: quote_address, };
        let caller_address = starknet::get_caller_address();

        // Create liquidity pool
        let jedi_router = IJediswapRouterDispatcher { contract_address: exchange_address };
        assert(jedi_router.contract_address.is_non_zero(), errors::EXCHANGE_ADDRESS_ZERO);
        let jedi_factory = IJediswapFactoryDispatcher { contract_address: jedi_router.factory(), };

        // Add liquidity - approve the supplied LP of the memecoin and quote token balances
        // to supply as liquidity
        // Transfer from caller to this contract so that jediswap can take the tokens from here
        quote_token.transferFrom(caller_address, this, quote_amount,);
        memecoin.approve(jedi_router.contract_address, lp_supply);
        quote_token.approve(jedi_router.contract_address, quote_amount);

        // As we're supplying the first liquidity for this pool,
        // The expected minimum amounts for each tokens are the amounts we're supplying.
        let (amount_memecoin, amount_eth, liquidity_received) = jedi_router
            .add_liquidity(
                memecoin_address,
                quote_address,
                lp_supply,
                quote_amount,
                lp_supply,
                quote_amount,
                this, // receiver of LP tokens is the factory, that instantly locks them
                deadline: get_block_timestamp()
            );
        let pair_address = jedi_factory.get_pair(memecoin_address, quote_address);
        let pair = ERC20ABIDispatcher { contract_address: pair_address, };

        // Lock LP tokens
        let lock_manager = ILockManagerDispatcher { contract_address: lock_manager_address };
        pair.approve(lock_manager_address, liquidity_received);
        let locked_address = lock_manager
            .lock_tokens(
                token: pair_address,
                amount: liquidity_received,
                unlock_time: unlock_time,
                withdrawer: caller_address,
            );

        pair.contract_address
    }
}
