use starknet::ContractAddress;

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

#[starknet::component]
mod JediswapComponent {
    use ERC20Component::InternalTrait; // required to use internals of ERC20Component
    use OwnableComponent::Ownable; // required to use internals of OwnableComponent
    use array::ArrayTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::interface::{
        IERC20, IERC20Metadata, ERC20ABIDispatcher, ERC20ABIDispatcherTrait
    };
    use starknet::{get_block_timestamp, ContractAddress};
    use super::{
        IJediswapRouterDispatcher, IJediswapRouterDispatcherTrait, IJediswapFactoryDispatcher,
        IJediswapFactoryDispatcherTrait
    };
    use unruggable::errors;
    use unruggable::locker::{ITokenLockerDispatcher, ITokenLockerDispatcherTrait};
    use unruggable::tokens::interface::{IUnruggableAdditional, IUnruggableMemecoinCamel};

    #[storage]
    struct Storage {}

    #[embeddable_as(JediswapAdapterImpl)]
    impl JediswapAdapter<
        TContractState,
        +HasComponent<TContractState>,
        // The contract embedding this componenet
        // must also embed ERC20Component
        impl ERC20: ERC20Component::HasComponent<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>,
        +IUnruggableMemecoinCamel<TContractState>,
        +IUnruggableAdditional<TContractState>,
        +Drop<TContractState>
    > of unruggable::exchanges::IAmmAdapter<ComponentState<TContractState>> {
        fn create_and_add_liquidity(
            ref self: ComponentState<TContractState>,
            exchange_address: ContractAddress,
            token_address: ContractAddress,
            counterparty_address: ContractAddress,
            unlock_time: u64,
            additional_parameters: Span<felt252>,
        ) -> ContractAddress {
            assert(additional_parameters.len() == 0, 'Invalid add liq params');

            // This component is made to be embedded inside the memecoin contract. In order to access
            // its functions, we need to get a mutable reference to the memecoin contract.
            let memecoin = self.get_contract_mut();

            // As the memecoin contract embeds ERC20Component, we need to get a mutable reference to
            // its ERC20 component in order to access its internal functions (such as _approve).
            let mut memecoin_erc20 = get_dep_component_mut!(ref self, ERC20);
            let mut memecoin_ownable = get_dep_component_mut!(ref self, Ownable);

            let memecoin_address = starknet::get_contract_address();
            let caller_address = starknet::get_caller_address();
            let counterparty_token = ERC20ABIDispatcher { contract_address: counterparty_address, };

            // Create liquidity pool
            let jedi_router = IJediswapRouterDispatcher { contract_address: exchange_address };
            assert(jedi_router.contract_address.is_non_zero(), errors::EXCHANGE_NOT_SUPPORTED);
            let jedi_factory = IJediswapFactoryDispatcher {
                contract_address: jedi_router.factory(),
            };
            let pair_address = jedi_factory.create_pair(counterparty_address, memecoin_address);

            // Add liquidity - approve the entirety of the memecoin and counterparty token balances
            // to supply as liquidity
            let memecoin_balance = memecoin.balanceOf(memecoin_address);
            let counterparty_token_balance = counterparty_token.balanceOf(memecoin_address);
            memecoin_erc20
                ._approve(memecoin_address, jedi_router.contract_address, memecoin_balance);
            counterparty_token.approve(jedi_router.contract_address, counterparty_token_balance);

            // As we're supplying the first liquidity for this pool,
            // The expected minimum amounts for each tokens are the amounts we're supplying.
            let (amount_memecoin, amount_eth, liquidity_received) = jedi_router
                .add_liquidity(
                    memecoin_address,
                    counterparty_address,
                    memecoin_balance,
                    counterparty_token_balance,
                    memecoin_balance,
                    counterparty_token_balance,
                    memecoin_address,
                    deadline: get_block_timestamp()
                );
            assert(
                memecoin.balanceOf(pair_address) == memecoin_balance, 'add liquidity meme failed'
            );
            assert(
                counterparty_token.balanceOf(pair_address) == counterparty_token_balance,
                'add liq counterparty failed'
            );
            let pair = ERC20ABIDispatcher { contract_address: pair_address, };

            assert(pair.balanceOf(memecoin_address) == liquidity_received, 'wrong LP tkns amount');

            // Lock LP tokens
            let locker_address = memecoin.locker_address();
            let locker_dispatcher = ITokenLockerDispatcher { contract_address: locker_address };
            pair.approve(locker_address, liquidity_received);
            //TODO(locker): make locktime dynamic
            locker_dispatcher
                .lock_tokens(
                    token: pair_address,
                    amount: liquidity_received,
                    :unlock_time,
                    withdrawer: memecoin_ownable.owner(),
                );
            assert(pair.balanceOf(locker_address) == liquidity_received, 'lock failed');

            pair.contract_address
        }
    }
}
