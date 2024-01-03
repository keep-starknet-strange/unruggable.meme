use openzeppelin::token::erc20::ERC20ABIDispatcher;
use starknet::ContractAddress;
use unruggable::exchanges::SupportedExchanges;

#[starknet::interface]
trait IFactory<TContractState> {
    /// Deploys a new memecoin, using the class hash that was registered in the factory upon initialization.
    ///
    /// This function deploys a new memecoin contract with the given parameters,
    /// transfers 1 ETH from the caller to the new memecoin, and emits a `MemeCoinCreated` event.
    ///
    /// * `owner` - The address of the Memecoin contract owner.
    /// * `LOCK_MANAGER_ADDRESS` - The address of the locker contract associated with the Memecoin.
    /// * `name` - The name of the Memecoin.
    /// * `symbol` - The symbol of the Memecoin.
    /// * `initial_supply` - The initial supply of the Memecoin.
    /// * `initial_holders` - An array containing the initial holders' addresses.
    /// * `initial_holders_amounts` - An array containing the initial amounts held by each corresponding initial holder.
    /// * `transfer_limit_delay` - The delay in seconds during which transfers will be limited to a % of max supply after launch.
    /// * `counterparty_token` - The address of the counterparty token
    /// * `contract_address_salt` - A unique salt value for contract deployment
    ///
    /// # Returns
    ///
    /// The address of the newly created Memecoin smart contract.
    fn create_memecoin(
        ref self: TContractState,
        owner: ContractAddress,
        lock_manager_address: ContractAddress,
        name: felt252,
        symbol: felt252,
        initial_supply: u256,
        initial_holders: Span<ContractAddress>,
        initial_holders_amounts: Span<u256>,
        transfer_limit_delay: u64,
        counterparty_token: ERC20ABIDispatcher,
        contract_address_salt: felt252
    ) -> ContractAddress;

    /// Returns the router address for a given Exchange, provided that this Exchange
    /// was registered in the factory upon initialization.
    ///
    /// # Arguments
    ///
    /// * `amm_name` - The name of the Exchange for which to retrieve the contract address.
    ///
    /// # Returns
    ///
    /// * `ContractAddress` - The contract address associated with the given Exchange name.
    fn exchange_address(self: @TContractState, amm: SupportedExchanges) -> ContractAddress;

    /// Checks if a given address is a memecoin.
    ///
    /// This function will only return true if the memecoin was created by this factory.
    ///
    /// # Arguments
    ///
    /// * `address` - The address to check.
    ///
    /// # Returns
    ///
    /// * `bool` - Returns true if the address is a memecoin, false otherwise.
    fn is_memecoin(self: @TContractState, address: ContractAddress) -> bool;
}
