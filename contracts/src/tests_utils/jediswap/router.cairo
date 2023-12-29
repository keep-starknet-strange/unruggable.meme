use starknet::ClassHash;
// @title JediSwap router for stateless execution of swaps Cairo 1.0
// @author Mesh Finance
// @license MIT
// @dev Based on the Uniswap V2 Router
//       https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol

use starknet::ContractAddress;


#[starknet::interface]
trait IPair<T> {
    fn get_reserves(self: @T) -> (u256, u256, u64);
    fn mint(ref self: T, to: ContractAddress) -> u256;
    fn burn(ref self: T, to: ContractAddress) -> (u256, u256);
    fn swap(
        ref self: T, amount0Out: u256, amount1Out: u256, to: ContractAddress, data: Array::<felt252>
    );
}

#[starknet::interface]
trait IFactory<T> {
    fn get_pair(self: @T, token0: ContractAddress, token1: ContractAddress) -> ContractAddress;
    fn create_pair(
        ref self: T, token0: ContractAddress, token1: ContractAddress
    ) -> ContractAddress;
}

//
// Contract Interface
//
#[starknet::interface]
trait IRouterC1<TContractState> {
    fn factory(self: @TContractState) -> ContractAddress;
    fn sort_tokens(
        self: @TContractState, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> (ContractAddress, ContractAddress);
    fn add_liquidity(
        ref self: TContractState,
        tokenA: ContractAddress,
        tokenB: ContractAddress,
        amountADesired: u256,
        amountBDesired: u256,
        amountAMin: u256,
        amountBMin: u256,
        to: ContractAddress,
        deadline: u64
    ) -> (u256, u256, u256);
}

#[starknet::contract]
mod RouterC1 {
    use array::{ArrayTrait, SpanTrait};

    use debug::PrintTrait;
    use integer::u256_from_felt252;
    use openzeppelin::token::erc20::interface::{
        IERC20CamelDispatcher, IERC20CamelDispatcherTrait, ERC20ABIDispatcher,
        ERC20ABIDispatcherTrait
    };
    use result::ResultTrait;
    use starknet::syscalls::{replace_class_syscall, call_contract_syscall};
    use starknet::{
        ContractAddress, ClassHash, SyscallResult, SyscallResultTrait, get_caller_address,
        get_block_timestamp, contract_address_const, contract_address_to_felt252
    };

    use super::{IPairDispatcher, IPairDispatcherTrait, IFactoryDispatcher, IFactoryDispatcherTrait};

    //
    // Storage
    //
    #[storage]
    struct Storage {
        _factory: ContractAddress, // @dev Factory contract address  
        Proxy_admin: ContractAddress, // @dev Admin contract address, to be used till we finalize Cairo upgrades.       
    }

    //
    // Constructor
    //

    // @notice Contract constructor
    // @param factory Address of factory contract
    #[constructor]
    fn constructor(ref self: ContractState, factory: ContractAddress) {
        assert(!factory.is_zero(), 'can not be zero');
        self._factory.write(factory);
    }

    #[external(v0)]
    impl RouterC1 of super::IRouterC1<ContractState> {
        // @notice factory address
        // @return address
        fn factory(self: @ContractState) -> ContractAddress {
            self._factory.read()
        }

        // @notice Sort tokens `tokenA` and `tokenB` by address
        // @param tokenA Address of tokenA
        // @param tokenB Address of tokenB
        // @return token0 First token
        // @return token1 Second token
        fn sort_tokens(
            self: @ContractState, tokenA: ContractAddress, tokenB: ContractAddress
        ) -> (ContractAddress, ContractAddress) {
            _sort_tokens(tokenA, tokenB)
        }

        // @notice Add liquidity to a pool
        // @dev `caller` should have already given the router an allowance of at least amountADesired/amountBDesired on tokenA/tokenB
        // @param tokenA Address of tokenA
        // @param tokenB Address of tokenB
        // @param amountADesired The amount of tokenA to add as liquidity
        // @param amountBDesired The amount of tokenB to add as liquidity
        // @param amountAMin Bounds the extent to which the B/A price can go up before the transaction reverts. Must be <= amountADesired
        // @param amountBMin Bounds the extent to which the A/B price can go up before the transaction reverts. Must be <= amountBDesired
        // @param to Recipient of liquidity tokens
        // @param deadline Timestamp after which the transaction will revert
        // @return amountA The amount of tokenA sent to the pool
        // @return amountB The amount of tokenB sent to the pool
        // @return liquidity The amount of liquidity tokens minted
        fn add_liquidity(
            ref self: ContractState,
            tokenA: ContractAddress,
            tokenB: ContractAddress,
            amountADesired: u256,
            amountBDesired: u256,
            amountAMin: u256,
            amountBMin: u256,
            to: ContractAddress,
            deadline: u64
        ) -> (u256, u256, u256) {
            _ensure_deadline(deadline);
            let (amountA, amountB) = InternalImpl::_add_liquidity(
                ref self, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin
            );
            let factory = self._factory.read();
            let pair = _pair_for(factory, tokenA, tokenB);
            let sender = get_caller_address();
            _transfer_token(tokenA, sender, pair, amountA);
            _transfer_token(tokenB, sender, pair, amountB);
            let pairDispatcher = IPairDispatcher { contract_address: pair };
            let liquidity = pairDispatcher.mint(to);
            (amountA, amountB, liquidity)
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        //
        // Internals
        //
        // used
        fn _add_liquidity(
            ref self: ContractState,
            tokenA: ContractAddress,
            tokenB: ContractAddress,
            amountADesired: u256,
            amountBDesired: u256,
            amountAMin: u256,
            amountBMin: u256,
        ) -> (u256, u256) {
            let factory = self._factory.read();
            let factoryDispatcher = IFactoryDispatcher { contract_address: factory };
            let pair = factoryDispatcher.get_pair(tokenA, tokenB);

            if (pair == contract_address_const::<0>()) {
                factoryDispatcher.create_pair(tokenA, tokenB);
            }

            let (reserveA, reserveB) = _get_reserves(factory, tokenA, tokenB);

            if (reserveA == 0.into() && reserveB == 0.into()) {
                return (amountADesired, amountBDesired);
            } else {
                let amountBOptimal = _quote(amountADesired, reserveA, reserveB);
                if amountBOptimal <= amountBDesired {
                    assert(amountBOptimal >= amountBMin, 'insufficient B amount');
                    return (amountADesired, amountBOptimal);
                } else {
                    let amountAOptimal = _quote(amountBDesired, reserveB, reserveA);
                    assert(amountAOptimal <= amountADesired, '');
                    assert(amountAOptimal >= amountAMin, 'insufficient A amount');
                    return (amountAOptimal, amountBDesired);
                }
            }
        }

        fn _swap(
            ref self: ContractState,
            current_index: u32,
            amounts_len: u32,
            ref amounts: Array::<u256>,
            path: Span::<ContractAddress>,
            _to: ContractAddress
        ) {
            let factory = self._factory.read();
            if (current_index == amounts_len - 1) {
                return ();
            }
            let (token0, _) = _sort_tokens(*path[current_index], *path[current_index + 1]);
            let mut amount0Out = 0.into();
            let mut amount1Out = 0.into();
            if (*path[current_index] == token0) {
                amount1Out = *amounts[current_index + 1];
            } else {
                amount0Out = *amounts[current_index + 1];
            }
            let mut to: ContractAddress = _to;
            if (current_index < (amounts_len - 2)) {
                to = _pair_for(factory, *path[current_index + 1], *path[current_index + 2]);
            }
            let pair = _pair_for(factory, *path[current_index], *path[current_index + 1]);
            let data = ArrayTrait::<felt252>::new();
            let pairDispatcher = IPairDispatcher { contract_address: pair };
            pairDispatcher.swap(amount0Out, amount1Out, to, data);
            return InternalImpl::_swap(
                ref self, current_index + 1, amounts_len, ref amounts, path, _to
            );
        }
    }

    //
    // Internals LIBRARY
    //

    fn _ensure_deadline(deadline: u64) {
        let block_timestamp = get_block_timestamp();
        assert(deadline >= block_timestamp, 'expired');
    }

    fn _transfer_token(
        token: ContractAddress, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) {
        let tokenDispatcher = IERC20CamelDispatcher { contract_address: token };
        tokenDispatcher
            .transferFrom(sender, recipient, amount); // TODO dispatcher with error handling
    }

    fn _sort_tokens(
        tokenA: ContractAddress, tokenB: ContractAddress
    ) -> (ContractAddress, ContractAddress) {
        assert(tokenA != tokenB, 'must not be identical');
        let mut token0: ContractAddress = contract_address_const::<0>();
        let mut token1: ContractAddress = contract_address_const::<0>();
        if u256_from_felt252(
            contract_address_to_felt252(tokenA)
        ) < u256_from_felt252(
            contract_address_to_felt252(tokenB)
        ) { // TODO token comparison directly
            token0 = tokenA;
            token1 = tokenB;
        } else {
            token0 = tokenB;
            token1 = tokenA;
        }

        assert(!token0.is_zero(), 'must be non zero');
        (token0, token1)
    }

    fn _pair_for(
        factory: ContractAddress, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> ContractAddress {
        let (token0, token1) = _sort_tokens(tokenA, tokenB);
        let factoryDispatcher = IFactoryDispatcher { contract_address: factory };
        let pair = factoryDispatcher.get_pair(token0, token1);
        pair
    }

    fn _get_reserves(
        factory: ContractAddress, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> (u256, u256) {
        let (token0, _) = _sort_tokens(tokenA, tokenB);
        let pair = _pair_for(factory, tokenA, tokenB);
        let pairDispatcher = IPairDispatcher { contract_address: pair };
        let (reserve0, reserve1, _) = pairDispatcher.get_reserves();
        if (tokenA == token0) {
            return (reserve0, reserve1);
        } else {
            return (reserve1, reserve0);
        }
    }

    fn _quote(amountA: u256, reserveA: u256, reserveB: u256) -> u256 {
        assert(amountA > 0.into(), 'insufficient amount');
        assert(reserveA > 0.into() && reserveB > 0.into(), 'insufficient liquidity');

        let amountB = (amountA * reserveB) / reserveA;
        amountB
    }
}
