use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starkent::Store)]
struct SwapPath {
    tokenIn: ContractAddress,
    tokenOut: ContractAddress,
    stable: bool,
    feeTier: u8,
}

#[starknet::interface]
trait IStarkDRouter<TContractState> {
    fn factory(self: @TContractState) -> ContractAddress;
    fn sort_tokens(
        self: @TContractState, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> (ContractAddress, ContractAddress);
    fn add_liquidity(
        ref self: TContractState,
        tokenA: ContractAddress,
        tokenB: ContractAddress,
        stable: bool,
        feeTier: u8,
        amountADesired: u256,
        amountBDesired: u256,
        amountAMin: u256,
        amountBMin: u256,
        to: ContractAddress,
        deadline: u64
    ) -> (u256, u256, u256);
    fn swap_exact_tokens_for_tokens(
        ref self: TContractState,
        amountIn: u256,
        amountOutMin: u256,
        path: Array::<SwapPath>,
        to: ContractAddress,
        deadline: u64
    ) -> Array::<u256>;
}

#[starknet::interface]
trait IStarkDFactory<TContractState> {
    fn get_pair(
        self: @TContractState,
        tokenA: ContractAddress,
        tokenB: ContractAddress,
        stable: bool,
        fee: u8
    ) -> ContractAddress;
    fn create_pair(
        ref self: TContractState,
        tokenA: ContractAddress,
        tokenB: ContractAddress,
        stable: bool,
        fee: u8
    ) -> ContractAddress;
}

#[starknet::interface]
trait IStarkDPair<TContractState> {
    fn totalSupply(self: @TContractState) -> u256;
    fn token0(self: @TContractState) -> ContractAddress;
    fn token1(self: @TContractState) -> ContractAddress;
    fn get_reserves(self: @TContractState) -> (u256, u256, u64);
    fn mint(ref self: TContractState, to: ContractAddress) -> u256;
}

#[derive(Copy, Drop)]
struct StarkDeFiAdditionalParameters {
    lock_manager_address: ContractAddress,
    unlock_time: u64,
    quote_amount: u256
}
