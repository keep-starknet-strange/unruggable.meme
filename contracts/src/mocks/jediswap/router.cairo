use starknet::ClassHash;
// @title JediSwap router for stateless execution of swaps Cairo 1.0
// @author Mesh Finance
// @license MIT
// @dev Based on the Uniswap V2 Router
//       https://github.com/Uniswap/v2-periphery/blob/master/contracts/UniswapV2Router02.sol

use starknet::ContractAddress;

#[starknet::interface]
trait IJediswapPair<T> {
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
trait IJediswapRouter<TContractState> {
    // view functions
    fn factory(self: @TContractState) -> ContractAddress;
    fn sort_tokens(
        self: @TContractState, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> (ContractAddress, ContractAddress);
    fn quote(self: @TContractState, amountA: u256, reserveA: u256, reserveB: u256) -> u256;
    fn get_amount_out(
        self: @TContractState, amountIn: u256, reserveIn: u256, reserveOut: u256
    ) -> u256;
    fn get_amount_in(
        self: @TContractState, amountOut: u256, reserveIn: u256, reserveOut: u256
    ) -> u256;
    fn get_amounts_out(
        self: @TContractState, amountIn: u256, path: Array::<ContractAddress>
    ) -> Array::<u256>;
    fn get_amounts_in(
        self: @TContractState, amountOut: u256, path: Array::<ContractAddress>
    ) -> Array::<u256>;
    // external functions
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
    fn remove_liquidity(
        ref self: TContractState,
        tokenA: ContractAddress,
        tokenB: ContractAddress,
        liquidity: u256,
        amountAMin: u256,
        amountBMin: u256,
        to: ContractAddress,
        deadline: u64
    ) -> (u256, u256);
    fn swap_exact_tokens_for_tokens(
        ref self: TContractState,
        amountIn: u256,
        amountOutMin: u256,
        path: Array::<ContractAddress>,
        to: ContractAddress,
        deadline: u64
    ) -> Array::<u256>;
    fn swap_tokens_for_exact_tokens(
        ref self: TContractState,
        amountOut: u256,
        amountInMax: u256,
        path: Array::<ContractAddress>,
        to: ContractAddress,
        deadline: u64
    ) -> Array::<u256>;
    fn replace_implementation_class(ref self: TContractState, new_implementation_class: ClassHash);
}

#[starknet::interface]
trait IERC20<T> {
    fn transfer_from(
        ref self: T, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn transferFrom(
        ref self: T, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool; // TODO Remove after regenesis
}

#[starknet::contract]
mod RouterC1 {
    use array::{ArrayTrait, SpanTrait};
    use integer::u256_from_felt252;
    use result::ResultTrait;
    use starknet::syscalls::{replace_class_syscall, call_contract_syscall};
    use starknet::{
        ContractAddress, ClassHash, SyscallResult, SyscallResultTrait, get_caller_address,
        get_block_timestamp, contract_address_const, contract_address_to_felt252
    };

    use super::{
        IERC20Dispatcher, IERC20DispatcherTrait, IJediswapPairDispatcher,
        IJediswapPairDispatcherTrait, IFactoryDispatcher, IFactoryDispatcherTrait
    };
    use traits::Into;
    use zeroable::Zeroable;

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
    impl RouterC1 of super::IJediswapRouter<ContractState> {
        //
        // Getters
        //

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

        // @notice Given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
        // @param amountA Amount of tokenA
        // @param reserveA Reserves for tokenA
        // @param reserveB Reserves for tokenB
        // @return amountB Amount of tokenB
        fn quote(self: @ContractState, amountA: u256, reserveA: u256, reserveB: u256) -> u256 {
            _quote(amountA, reserveA, reserveB)
        }

        // @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
        // @param amountIn Input Amount
        // @param reserveIn Reserves for input token
        // @param reserveOut Reserves for output token
        // @return amountOut Maximum output amount
        fn get_amount_out(
            self: @ContractState, amountIn: u256, reserveIn: u256, reserveOut: u256
        ) -> u256 {
            _get_amount_out(amountIn, reserveIn, reserveOut)
        }

        // @notice Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
        // @param amountOut Output Amount
        // @param reserveIn Reserves for input token
        // @param reserveOut Reserves for output token
        // @return amountIn Required input amount
        fn get_amount_in(
            self: @ContractState, amountOut: u256, reserveIn: u256, reserveOut: u256
        ) -> u256 {
            _get_amount_in(amountOut, reserveIn, reserveOut)
        }

        // @notice Performs chained get_amount_out calculations on any number of pairs
        // @param amountIn Input Amount
        // @param path Array of pair addresses through which swaps are chained
        // @return amounts Required output amount array
        fn get_amounts_out(
            self: @ContractState, amountIn: u256, path: Array::<ContractAddress>
        ) -> Array::<u256> {
            let factory = self._factory.read();
            _get_amounts_out(factory, amountIn, path.span())
        }

        // @notice Performs chained get_amount_in calculations on any number of pairs
        // @param amountOut Output Amount
        // @param path Array of pair addresses through which swaps are chained
        // @return amounts Required input amount array
        fn get_amounts_in(
            self: @ContractState, amountOut: u256, path: Array::<ContractAddress>
        ) -> Array::<u256> {
            let factory = self._factory.read();
            _get_amounts_in(factory, amountOut, path.span())
        }

        //
        // Externals
        //

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
            let pairDispatcher = IJediswapPairDispatcher { contract_address: pair };
            let liquidity = pairDispatcher.mint(to);
            (amountA, amountB, liquidity)
        }

        // @notice Remove liquidity from a pool
        // @dev `caller` should have already given the router an allowance of at least liquidity on the pool
        // @param tokenA Address of tokenA
        // @param tokenB Address of tokenB
        // @param liquidity The amount of liquidity tokens to remove
        // @param amountAMin The minimum amount of tokenA that must be received for the transaction not to revert
        // @param amountBMin The minimum amount of tokenB that must be received for the transaction not to revert
        // @param to Recipient of the underlying tokens
        // @param deadline Timestamp after which the transaction will revert
        // @return amountA The amount of tokenA received
        // @return amountB The amount of tokenB received
        fn remove_liquidity(
            ref self: ContractState,
            tokenA: ContractAddress,
            tokenB: ContractAddress,
            liquidity: u256,
            amountAMin: u256,
            amountBMin: u256,
            to: ContractAddress,
            deadline: u64
        ) -> (u256, u256) {
            _ensure_deadline(deadline);
            let factory = self._factory.read();
            let pair = _pair_for(factory, tokenA, tokenB);
            let sender = get_caller_address();
            _transfer_token(pair, sender, pair, liquidity);
            let pairDispatcher = IJediswapPairDispatcher { contract_address: pair };
            let (amount0, amount1) = pairDispatcher.burn(to);
            let (token0, _) = _sort_tokens(tokenA, tokenB);
            let mut amountA = 0.into();
            let mut amountB = 0.into();
            if tokenA == token0 {
                amountA = amount0;
                amountB = amount1;
            } else {
                amountA = amount1;
                amountB = amount0;
            }

            assert(amountA >= amountAMin, 'insufficient A amount');
            assert(amountB >= amountBMin, 'insufficient B amount');

            (amountA, amountB)
        }

        // @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path
        // @dev `caller` should have already given the router an allowance of at least amountIn on the input token
        // @param amountIn The amount of input tokens to send
        // @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert
        // @param path Array of pair addresses through which swaps are chained
        // @param to Recipient of the output tokens
        // @param deadline Timestamp after which the transaction will revert
        // @return amounts The input token amount and all subsequent output token amounts
        fn swap_exact_tokens_for_tokens(
            ref self: ContractState,
            amountIn: u256,
            amountOutMin: u256,
            path: Array::<ContractAddress>,
            to: ContractAddress,
            deadline: u64
        ) -> Array::<u256> {
            _ensure_deadline(deadline);
            let factory = self._factory.read();
            let mut amounts = _get_amounts_out(factory, amountIn, path.span());
            assert(*amounts[amounts.len() - 1] >= amountOutMin, 'insufficient output amount');
            let pair = _pair_for(factory, *path[0], *path[1]);
            let sender = get_caller_address();
            _transfer_token(*path[0], sender, pair, *amounts[0]);
            InternalImpl::_swap(ref self, 0, path.len(), ref amounts, path.span(), to);
            amounts
        }

        // @notice Receive an exact amount of output tokens for as few input tokens as possible, along the route determined by the path
        // @dev `caller` should have already given the router an allowance of at least amountInMax on the input token
        // @param amountOut The amount of output tokens to receive
        // @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts
        // @param path Array of pair addresses through which swaps are chained
        // @param to Recipient of the output tokens
        // @param deadline Timestamp after which the transaction will revert
        // @return amounts The input token amount and all subsequent output token amounts
        fn swap_tokens_for_exact_tokens(
            ref self: ContractState,
            amountOut: u256,
            amountInMax: u256,
            path: Array::<ContractAddress>,
            to: ContractAddress,
            deadline: u64
        ) -> Array::<u256> {
            _ensure_deadline(deadline);
            let factory = self._factory.read();
            let mut amounts = _get_amounts_in(factory, amountOut, path.span());
            assert(*amounts[0] <= amountInMax, 'excessive input amount');
            let pair = _pair_for(factory, *path[0], *path[1]);
            let sender = get_caller_address();
            _transfer_token(*path[0], sender, pair, *amounts[0]);
            InternalImpl::_swap(ref self, 0, path.len(), ref amounts, path.span(), to);
            amounts
        }

        // @notice This is used upgrade (Will push a upgrade without this to finalize)
        // @dev Only Proxy_admin can call
        // @param new_implementation_class New implementation hash
        fn replace_implementation_class(
            ref self: ContractState, new_implementation_class: ClassHash
        ) {
            let sender = get_caller_address();
            let proxy_admin = self.Proxy_admin.read();
            assert(sender == proxy_admin, 'must be admin');
            assert(!new_implementation_class.is_zero(), 'must be non zero');
            replace_class_syscall(new_implementation_class);
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        //
        // Internals
        //

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
            let pairDispatcher = IJediswapPairDispatcher { contract_address: pair };
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
        // let tokenDispatcher = IERC20Dispatcher { contract_address: token };
        // tokenDispatcher.transfer_from(sender, recipient, amount) // TODO dispatcher with error handling

        let mut calldata = Default::default();
        Serde::serialize(@sender, ref calldata);
        Serde::serialize(@recipient, ref calldata);
        Serde::serialize(@amount, ref calldata);

        let selector_for_transfer_from =
            1555377517929037318987687899825758707538299441176447799544473656894800517992;
        let selector_for_transferFrom =
            116061167288211781254449158074459916871457383008289084697957612485591092000;

        let mut result = call_contract_syscall(token, selector_for_transfer_from, calldata.span());
        if (result.is_err()) {
            result = call_contract_syscall(token, selector_for_transferFrom, calldata.span());
        }
        result.unwrap_syscall(); // Additional error handling
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
        let pairDispatcher = IJediswapPairDispatcher { contract_address: pair };
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

    fn _get_amount_out(amountIn: u256, reserveIn: u256, reserveOut: u256) -> u256 {
        assert(amountIn > 0.into(), 'insufficient input amount');
        assert(reserveIn > 0.into() && reserveOut > 0.into(), 'insufficient liquidity');

        let amountIn_with_fee = amountIn * 997.into();
        let numerator = amountIn_with_fee * reserveOut;
        let denominator = (reserveIn * 1000.into()) + amountIn_with_fee;

        numerator / denominator
    }

    fn _get_amount_in(amountOut: u256, reserveIn: u256, reserveOut: u256) -> u256 {
        assert(amountOut > 0.into(), 'insufficient output amount');
        assert(reserveIn > 0.into() && reserveOut > 0.into(), 'insufficient liquidity');

        let numerator = reserveIn * amountOut * 1000.into();
        let denominator = (reserveOut - amountOut) * 997.into();

        (numerator / denominator) + 1.into()
    }

    fn _get_amounts_out(
        factory: ContractAddress, amountIn: u256, path: Span::<ContractAddress>
    ) -> Array::<u256> {
        assert(path.len() >= 2, 'invalid path');
        let mut amounts = ArrayTrait::<u256>::new();
        amounts.append(amountIn);
        let mut current_index = 0;
        loop {
            if (current_index == path.len() - 1) {
                break true;
            }
            let (reserveIn, reserveOut) = _get_reserves(
                factory, *path[current_index], *path[current_index + 1]
            );
            amounts.append(_get_amount_out(*amounts[current_index], reserveIn, reserveOut));
            current_index += 1;
        };
        amounts
    }

    fn _get_amounts_in(
        factory: ContractAddress, amountOut: u256, path: Span::<ContractAddress>
    ) -> Array::<u256> {
        assert(path.len() >= 2, 'invalid path');
        let mut amounts = ArrayTrait::<u256>::new();
        amounts.append(amountOut);
        let mut current_index = path.len() - 1;
        loop {
            if (current_index == 0) {
                break true;
            }
            let (reserveIn, reserveOut) = _get_reserves(
                factory, *path[current_index - 1], *path[current_index]
            );
            amounts.append(_get_amount_in(*amounts[amounts.len() - 1], reserveIn, reserveOut));
            current_index -= 1;
        };
        let mut final_amounts = ArrayTrait::<u256>::new();
        current_index = 0;
        loop { // reversing array, TODO remove when set comes.
            if (current_index == amounts.len()) {
                break true;
            }
            final_amounts.append(*amounts[amounts.len() - 1 - current_index]);
            current_index += 1;
        };
        final_amounts
    }
}
