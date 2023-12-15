// @title JediSwap Pair Cairo 1.0
// @author Mesh Finance
// @license MIT
// @notice Low level pair contract
// @dev Based on the Uniswap V2 pair
//      https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
//      Also an ERC20 token

use starknet::ContractAddress;
use starknet::ClassHash;
//
// External Interfaces
//
#[starknet::interface]
trait IERC20<T> {
    fn balance_of(self: @T, account: ContractAddress) -> u256;
    fn balanceOf(self: @T, account: ContractAddress) -> u256; // TODO Remove after regenesis
    fn transfer(ref self: T, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: T, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn transferFrom(
        ref self: T, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool; // TODO Remove after regenesis
}

#[starknet::interface]
trait IFactory<T> {
    fn get_fee_to(self: @T) -> ContractAddress;
}

#[starknet::interface]
trait IJediSwapCallee<T> {
    fn jediswap_call(
        ref self: T,
        sender: ContractAddress,
        amount0Out: u256,
        amount1Out: u256,
        data: Array::<felt252>
    );
}

//
// Contract Interface
//
#[starknet::interface]
trait IPairC1<TContractState> {
    // view functions
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn total_supply(self: @TContractState) -> u256;
    fn totalSupply(self: @TContractState) -> u256; //TODO Remove after regenesis?
    fn decimals(self: @TContractState) -> u8;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn balanceOf(
        self: @TContractState, account: ContractAddress
    ) -> u256; //TODO Remove after regenesis?
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn token0(self: @TContractState) -> ContractAddress;
    fn token1(self: @TContractState) -> ContractAddress;
    fn get_reserves(self: @TContractState) -> (u256, u256, u64);
    fn price_0_cumulative_last(self: @TContractState) -> u256;
    fn price_1_cumulative_last(self: @TContractState) -> u256;
    fn klast(self: @TContractState) -> u256;
    // external functions
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn transferFrom(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool; //TODO Remove after regenesis?
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn increase_allowance(
        ref self: TContractState, spender: ContractAddress, added_value: u256
    ) -> bool;
    fn increaseAllowance(
        ref self: TContractState, spender: ContractAddress, added_value: u256
    ) -> bool; //TODO Remove after regenesis?
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    ) -> bool;
    fn decreaseAllowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    ) -> bool; //TODO Remove after regenesis?
    fn mint(ref self: TContractState, to: ContractAddress) -> u256;
    fn burn(ref self: TContractState, to: ContractAddress) -> (u256, u256);
    fn swap(
        ref self: TContractState,
        amount0Out: u256,
        amount1Out: u256,
        to: ContractAddress,
        data: Array::<felt252>
    );
    fn skim(ref self: TContractState, to: ContractAddress);
    fn sync(ref self: TContractState);
    fn replace_implementation_class(ref self: TContractState, new_implementation_class: ClassHash);
}

#[starknet::contract]
mod PairC1 {
    use unruggable::tests_utils::erc_20::ERC20;
    use array::{ArrayTrait, SpanTrait};
    use result::ResultTrait;
    use zeroable::Zeroable;
    use starknet::{
        ContractAddress, ClassHash, SyscallResult, SyscallResultTrait, get_caller_address,
        get_contract_address, get_block_timestamp, contract_address_const
    };
    use integer::{u128_try_from_felt252, u256_sqrt, u256_from_felt252};
    use starknet::syscalls::{replace_class_syscall, call_contract_syscall};

    use super::{
        IERC20Dispatcher, IERC20DispatcherTrait, IFactoryDispatcher, IFactoryDispatcherTrait,
        IJediSwapCalleeDispatcher, IJediSwapCalleeDispatcherTrait
    };

    //
    // Storage Pair
    //
    #[storage]
    struct Storage {
        _token0: ContractAddress, // @dev token0 address
        _token1: ContractAddress, // @dev token1 address
        _reserve0: u256, // @dev reserve for token0
        _reserve1: u256, // @dev reserve for token1
        _block_timestamp_last: u64, // @dev block timestamp for last update
        _price_0_cumulative_last: u256, // @dev cumulative price for token0 on last update
        _price_1_cumulative_last: u256, // @dev cumulative price for token1 on last update
        _klast: u256, // @dev reserve0 * reserve1, as of immediately after the most recent liquidity event
        _locked: bool, // @dev Boolean to check reentrancy
        _factory: ContractAddress, // @dev Factory contract address
        Proxy_admin: ContractAddress, // @dev Admin contract address, to be used till we finalize Cairo upgrades.
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Mint: Mint,
        Burn: Burn,
        Swap: Swap,
        Sync: Sync
    }

    // @notice An event emitted whenever mint() is called.
    #[derive(Drop, starknet::Event)]
    struct Mint {
        sender: ContractAddress,
        amount0: u256,
        amount1: u256
    }

    // @notice An event emitted whenever burn() is called.
    #[derive(Drop, starknet::Event)]
    struct Burn {
        sender: ContractAddress,
        amount0: u256,
        amount1: u256,
        to: ContractAddress
    }

    // @notice An event emitted whenever swap() is called.
    #[derive(Drop, starknet::Event)]
    struct Swap {
        sender: ContractAddress,
        amount0In: u256,
        amount1In: u256,
        amount0Out: u256,
        amount1Out: u256,
        to: ContractAddress
    }

    // @notice An event emitted whenever _update() is called.
    #[derive(Drop, starknet::Event)]
    struct Sync {
        reserve0: u256,
        reserve1: u256
    }

    //
    // Constructor
    //

    // @notice Contract constructor
    // @param name Name of the pair token
    // @param symbol Symbol of the pair token
    // @param token0 Address of token0
    // @param token1 Address of token1
    #[constructor]
    fn constructor(ref self: ContractState, token0: ContractAddress, token1: ContractAddress) {
        assert(!token0.is_zero() & !token1.is_zero(), 'must be non zero');
        let mut erc20_state = ERC20::unsafe_new_contract_state();
        ERC20::InternalImpl::initializer(ref erc20_state, 'JediSwap Pair', 'JEDI-P');
        self._locked.write(false);
        self._token0.write(token0);
        self._token1.write(token1);
        let factory = get_caller_address();
        self._factory.write(factory);
    }

    #[external(v0)]
    impl PairC1 of super::IPairC1<ContractState> {
        //
        // Getters ERC20
        //

        // @notice Name of the token
        // @return name
        fn name(self: @ContractState) -> felt252 {
            let erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::name(@erc20_state)
        }

        // @notice Symbol of the token
        // @return symbol
        fn symbol(self: @ContractState) -> felt252 {
            let erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::symbol(@erc20_state)
        }

        // @notice Total Supply of the token
        // @return total supply
        fn total_supply(self: @ContractState) -> u256 {
            let erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::total_supply(@erc20_state)
        }

        // @notice Total Supply of the token
        // @return totalSupply
        fn totalSupply(self: @ContractState) -> u256 {
            let erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::total_supply(@erc20_state)
        }

        // @notice Decimals of the token
        // @return decimals
        fn decimals(self: @ContractState) -> u8 {
            let erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::decimals(@erc20_state)
        }

        // @notice Balance of `account`
        // @param account Account address whose balance is fetched
        // @return balance Balance of `account`
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::balance_of(@erc20_state, account)
        }

        // @notice Balance of `account`
        // @param account Account address whose balance is fetched
        // @return balance Balance of `account`
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            let erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::balance_of(@erc20_state, account)
        }

        // @notice Allowance which `spender` can spend on behalf of `owner`
        // @param owner Account address whose tokens are spent
        // @param spender Account address which can spend the tokens
        // @return remaining
        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            let erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::allowance(@erc20_state, owner, spender)
        }

        //
        // Getters Pair
        //

        // @notice token0 address
        // @return address
        fn token0(self: @ContractState) -> ContractAddress {
            self._token0.read()
        }

        // @notice token1 address
        // @return address
        fn token1(self: @ContractState) -> ContractAddress {
            self._token1.read()
        }

        // @notice Current reserves for tokens in the pair
        // @return reserve0 reserve for token0
        // @return reserve1 reserve for token1
        // @return block_timestamp_last block timestamp for last update
        fn get_reserves(self: @ContractState) -> (u256, u256, u64) {
            InternalImpl::_get_reserves(self)
        }

        // @notice cumulative price for token0 on last update
        // @return res
        fn price_0_cumulative_last(self: @ContractState) -> u256 {
            self._price_0_cumulative_last.read()
        }

        // @notice cumulative price for token1 on last update
        // @return res
        fn price_1_cumulative_last(self: @ContractState) -> u256 {
            self._price_1_cumulative_last.read()
        }

        // @notice reserve0 * reserve1, as of immediately after the most recent liquidity event
        // @return res
        fn klast(self: @ContractState) -> u256 {
            self._klast.read()
        }

        //
        // Externals ERC20
        //

        // @notice Transfer `amount` tokens from `caller` to `recipient`
        // @param recipient Account address to which tokens are transferred
        // @param amount Amount of tokens to transfer
        // @return success 0 or 1
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let mut erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::transfer(ref erc20_state, recipient, amount);
            true
        }

        // @notice Transfer `amount` tokens from `sender` to `recipient`
        // @dev Checks for allowance.
        // @param sender Account address from which tokens are transferred
        // @param recipient Account address to which tokens are transferred
        // @param amount Amount of tokens to transfer
        // @return success 0 or 1
        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let mut erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::transfer_from(ref erc20_state, sender, recipient, amount);
            true
        }

        // @notice Transfer `amount` tokens from `sender` to `recipient`
        // @dev Checks for allowance.
        // @param sender Account address from which tokens are transferred
        // @param recipient Account address to which tokens are transferred
        // @param amount Amount of tokens to transfer
        // @return success 0 or 1
        fn transferFrom(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let mut erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::transfer_from(ref erc20_state, sender, recipient, amount);
            true
        }

        // @notice Approve `spender` to transfer `amount` tokens on behalf of `caller`
        // @param spender The address which will spend the funds
        // @param amount The amount of tokens to be spent
        // @return success 0 or 1
        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let mut erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::approve(ref erc20_state, spender, amount);
            true
        }

        // @notice Increase allowance of `spender` to transfer `added_value` more tokens on behalf of `caller`
        // @param spender The address which will spend the funds
        // @param added_value The increased amount of tokens to be spent
        // @return success 0 or 1
        fn increase_allowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) -> bool {
            let mut erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::increase_allowance(ref erc20_state, spender, added_value);
            true
        }

        // @notice Increase allowance of `spender` to transfer `added_value` more tokens on behalf of `caller`
        // @param spender The address which will spend the funds
        // @param added_value The increased amount of tokens to be spent
        // @return success 0 or 1
        fn increaseAllowance(
            ref self: ContractState, spender: ContractAddress, added_value: u256
        ) -> bool {
            let mut erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::increase_allowance(ref erc20_state, spender, added_value);
            true
        }

        // @notice Decrease allowance of `spender` to transfer `subtracted_value` less tokens on behalf of `caller`
        // @param spender The address which will spend the funds
        // @param subtracted_value The decreased amount of tokens to be spent
        // @return success 0 or 1
        fn decrease_allowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u256
        ) -> bool {
            let mut erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::decrease_allowance(ref erc20_state, spender, subtracted_value);
            true
        }

        // @notice Decrease allowance of `spender` to transfer `subtracted_value` less tokens on behalf of `caller`
        // @param spender The address which will spend the funds
        // @param subtracted_value The decreased amount of tokens to be spent
        // @return success 0 or 1
        fn decreaseAllowance(
            ref self: ContractState, spender: ContractAddress, subtracted_value: u256
        ) -> bool {
            let mut erc20_state = ERC20::unsafe_new_contract_state();
            ERC20::ERC20::decrease_allowance(ref erc20_state, spender, subtracted_value);
            true
        }

        //
        // Externals Pair
        //

        // @notice Mint tokens and assign them to `to`
        // @dev This low-level function should be called from a contract which performs important safety checks
        // @param to The account that will receive the created tokens
        // @return liquidity New tokens created
        fn mint(ref self: ContractState, to: ContractAddress) -> u256 {
            InternalImpl::_check_and_lock(ref self);
            let (reserve0, reserve1, _) = InternalImpl::_get_reserves(@self);
            let self_address = get_contract_address();
            let token0 = self._token0.read();
            let balance0 = _balance_of_token(token0, self_address);
            let token1 = self._token1.read();
            let balance1 = _balance_of_token(token1, self_address);
            let amount0 = balance0 - reserve0;
            let amount1 = balance1 - reserve1;
            let fee_on = InternalImpl::_mint_protocol_fee(ref self, reserve0, reserve1);
            let _total_supply = PairC1::total_supply(@self);
            let mut liquidity = 0.into();
            if (_total_supply == 0.into()) {
                liquidity =
                    u256 { low: u256_sqrt(amount0 * amount1) - 1000.try_into().unwrap(), high: 0 };
            } else {
                let liquidity0 = (amount0 * _total_supply) / reserve0;
                let liquidity1 = (amount1 * _total_supply) / reserve1;
                if liquidity0 < liquidity1 {
                    liquidity = liquidity0;
                } else {
                    liquidity = liquidity1;
                }
            }

            assert(liquidity > 0.into(), 'insufficient liquidity minted');

            let mut erc20_state = ERC20::unsafe_new_contract_state();
            if (_total_supply == 0.into()) {
                ERC20::InternalImpl::_mint(
                    ref erc20_state, contract_address_const::<1>(), 1000.into()
                );
            }
            ERC20::InternalImpl::_mint(ref erc20_state, to, liquidity);

            InternalImpl::_update(ref self, balance0, balance1, reserve0, reserve1);

            if (fee_on) {
                let klast = balance0 * balance1;
                self._klast.write(klast);
            }

            self
                .emit(
                    Mint { sender: get_caller_address(), amount0: amount0, amount1: amount1 }
                ); // TODO?? sender address instead of caller address

            InternalImpl::_unlock(ref self);
            liquidity
        }

        // @notice Burn tokens belonging to `to`
        // @dev This low-level function should be called from a contract which performs important safety checks
        // @param to The account that will receive the created tokens
        // @return amount0 Amount of token0 received
        // @return amount1 Amount of token1 received
        fn burn(ref self: ContractState, to: ContractAddress) -> (u256, u256) {
            InternalImpl::_check_and_lock(ref self);
            let (reserve0, reserve1, _) = InternalImpl::_get_reserves(@self);
            let self_address = get_contract_address();
            let token0 = self._token0.read();
            let mut balance0 = _balance_of_token(token0, self_address);
            let token1 = self._token1.read();
            let mut balance1 = _balance_of_token(token1, self_address);
            let liquidity = PairC1::balance_of(@self, self_address);
            let fee_on = InternalImpl::_mint_protocol_fee(ref self, reserve0, reserve1);
            let _total_supply = PairC1::total_supply(@self);

            let amount0 = (liquidity * balance0) / _total_supply;
            let amount1 = (liquidity * balance1) / _total_supply;
            assert(amount0 > 0.into() && amount1 > 0.into(), 'insufficient liquidity burned');

            let mut erc20_state = ERC20::unsafe_new_contract_state();

            ERC20::InternalImpl::_burn(ref erc20_state, self_address, liquidity);

            let token0Dispatcher = IERC20Dispatcher { contract_address: token0 };
            token0Dispatcher.transfer(to, amount0);
            let token1Dispatcher = IERC20Dispatcher { contract_address: token1 };
            token1Dispatcher.transfer(to, amount1);

            balance0 = _balance_of_token(token0, self_address);
            balance1 = _balance_of_token(token1, self_address);

            InternalImpl::_update(ref self, balance0, balance1, reserve0, reserve1);

            if (fee_on) {
                let klast = balance0 * balance1;
                self._klast.write(klast);
            }

            self
                .emit(
                    Burn {
                        sender: get_caller_address(), amount0: amount0, amount1: amount1, to: to
                    }
                );

            InternalImpl::_unlock(ref self);
            (amount0, amount1)
        }

        // @notice Swaps from one token to another
        // @dev This low-level function should be called from a contract which performs important safety checks
        // @param amount0Out Amount of token0 received
        // @param amount1Out Amount of token1 received
        // @param to The account that will receive the tokens
        fn swap(
            ref self: ContractState,
            amount0Out: u256,
            amount1Out: u256,
            to: ContractAddress,
            data: Array::<felt252>
        ) {
            InternalImpl::_check_and_lock(ref self);
            assert(amount0Out > 0.into() || amount1Out > 0.into(), 'insufficient output amount');

            let (reserve0, reserve1, _) = InternalImpl::_get_reserves(@self);
            assert(amount0Out < reserve0 && amount1Out < reserve1, 'insufficient liquidity');

            let token0 = self._token0.read();
            let token1 = self._token1.read();
            assert(to != token0 && to != token1, 'invalid to');

            let token0Dispatcher = IERC20Dispatcher { contract_address: token0 };
            let token1Dispatcher = IERC20Dispatcher { contract_address: token1 };

            if (amount0Out > 0.into()) {
                token0Dispatcher.transfer(to, amount0Out);
            }

            if (amount1Out > 0.into()) {
                token1Dispatcher.transfer(to, amount1Out);
            }

            if (data.len() > 0) {
                let JediSwapCalleeDispatcher = IJediSwapCalleeDispatcher { contract_address: to };
                JediSwapCalleeDispatcher
                    .jediswap_call(get_caller_address(), amount0Out, amount1Out, data);
            }

            let self_address = get_contract_address();
            let balance0 = _balance_of_token(token0, self_address);
            let balance1 = _balance_of_token(token1, self_address);

            let mut amount0In = 0.into();

            if (balance0 > (reserve0 - amount0Out)) {
                amount0In = balance0 - (reserve0 - amount0Out);
            }

            let mut amount1In = 0.into();

            if (balance1 > (reserve1 - amount1Out)) {
                amount1In = balance1 - (reserve1 - amount1Out);
            }

            assert(amount0In > 0.into() || amount1In > 0.into(), 'insufficient input amount');

            let balance0Adjusted = (balance0 * 1000.into()) - (amount0In * 3.into());
            let balance1Adjusted = (balance1 * 1000.into()) - (amount1In * 3.into());

            assert(
                balance0Adjusted * balance1Adjusted > reserve0 * reserve1 * 1000000.into(),
                'invariant K'
            );

            InternalImpl::_update(ref self, balance0, balance1, reserve0, reserve1);

            self
                .emit(
                    Swap {
                        sender: get_caller_address(),
                        amount0In: amount0In,
                        amount1In: amount1In,
                        amount0Out: amount0Out,
                        amount1Out: amount1Out,
                        to: to
                    }
                );

            InternalImpl::_unlock(ref self);
        }

        // @notice force balances to match reserves
        // @param to The account that will receive the balance tokens
        fn skim(ref self: ContractState, to: ContractAddress) {
            InternalImpl::_check_and_lock(ref self);
            let (reserve0, reserve1, _) = InternalImpl::_get_reserves(@self);

            let self_address = get_contract_address();
            let token0 = self._token0.read();
            let balance0 = _balance_of_token(token0, self_address);
            let token1 = self._token1.read();
            let balance1 = _balance_of_token(token1, self_address);

            let token0Dispatcher = IERC20Dispatcher { contract_address: token0 };
            token0Dispatcher.transfer(to, balance0 - reserve0);
            let token1Dispatcher = IERC20Dispatcher { contract_address: token1 };
            token1Dispatcher.transfer(to, balance1 - reserve1);

            InternalImpl::_unlock(ref self);
        }

        // @notice Force reserves to match balances
        fn sync(ref self: ContractState) {
            InternalImpl::_check_and_lock(ref self);

            let self_address = get_contract_address();
            let token0 = self._token0.read();
            let balance0 = _balance_of_token(token0, self_address);
            let token1 = self._token1.read();
            let balance1 = _balance_of_token(token1, self_address);

            let (reserve0, reserve1, _) = InternalImpl::_get_reserves(@self);

            InternalImpl::_update(ref self, balance0, balance1, reserve0, reserve1);

            InternalImpl::_unlock(ref self);
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
        // Internals Pair
        //

        // @dev Check if the entry is not locked, and lock it
        fn _check_and_lock(ref self: ContractState) {
            let locked = self._locked.read();
            assert(!locked, 'locked');
            self._locked.write(true);
        }

        // @dev Unlock the entry
        fn _unlock(ref self: ContractState) {
            let locked = self._locked.read();
            assert(locked, 'not locked');
            self._locked.write(false);
        }

        // @dev If fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
        fn _mint_protocol_fee(ref self: ContractState, reserve0: u256, reserve1: u256) -> bool {
            let factory = self._factory.read();
            let factoryDispatcher = IFactoryDispatcher { contract_address: factory };
            let fee_to = factoryDispatcher.get_fee_to();
            let fee_on = (fee_to != contract_address_const::<0>());

            let klast = self._klast.read();

            if (fee_on) {
                if (klast != 0.into()) {
                    let rootk = u256 { low: u256_sqrt(reserve0 * reserve1), high: 0 };
                    let rootklast = u256 { low: u256_sqrt(klast), high: 0 };
                    if (rootk > rootklast) {
                        let numerator = PairC1::total_supply(@self) * (rootk - rootklast);
                        let denominator = (rootk * 5.into()) + rootklast;
                        let liquidity = numerator / denominator;
                        if (liquidity > 0.into()) {
                            let mut erc20_state = ERC20::unsafe_new_contract_state();
                            ERC20::InternalImpl::_mint(ref erc20_state, fee_to, liquidity);
                        }
                    }
                }
            } else {
                if (klast != 0.into()) {
                    self._klast.write(0.into());
                }
            }
            fee_on
        }

        fn _get_reserves(self: @ContractState) -> (u256, u256, u64) {
            (self._reserve0.read(), self._reserve1.read(), self._block_timestamp_last.read())
        }

        // @dev Update reserves and, on the first call per block, price accumulators
        fn _update(
            ref self: ContractState, balance0: u256, balance1: u256, reserve0: u256, reserve1: u256
        ) {
            assert(balance0.high == 0 && balance1.high == 0, 'overflow');
            let block_timestamp = get_block_timestamp();
            let block_timestamp_last = self._block_timestamp_last.read();
            let time_elapsed = block_timestamp - block_timestamp_last;
            let (reserve0, reserve1, _) = InternalImpl::_get_reserves(@self);
            if (time_elapsed > 0 && reserve0 != 0.into() && reserve1 != 0.into()) {
                let mut price_0_cumulative_last = self._price_0_cumulative_last.read();
                let mut price_1_cumulative_last = self._price_1_cumulative_last.read();
                price_0_cumulative_last += (reserve1 / reserve0)
                    * u256 {
                        low: u128_try_from_felt252(time_elapsed.into()).unwrap(), high: 0
                    }; // TODO official support for casting to u256
                price_1_cumulative_last += (reserve0 / reserve1)
                    * u256 {
                        low: u128_try_from_felt252(time_elapsed.into()).unwrap(), high: 0
                    }; // TODO official support for casting to u256
                self._price_0_cumulative_last.write(price_0_cumulative_last);
                self._price_1_cumulative_last.write(price_1_cumulative_last);
            }

            self._reserve0.write(balance0);
            self._reserve1.write(balance1);
            self._block_timestamp_last.write(block_timestamp);

            self.emit(Sync { reserve0: balance0, reserve1: balance1 });
        }
    }

    //
    // Internals LIBRARY
    //

    fn _balance_of_token(token: ContractAddress, account: ContractAddress) -> u256 {
        // let tokenDispatcher = IERC20Dispatcher { contract_address: token };
        // tokenDispatcher.balance_of(account)

        let mut calldata = Default::default();
        Serde::serialize(@account, ref calldata);

        let selector_for_balance_of =
            1516754014369808875012295842270199525215452866521012470027807093200784961331;
        let selector_for_balanceOf =
            1307730684388977109649524593492043083703013045633289330664425380824804018030;

        let mut result = call_contract_syscall(token, selector_for_balance_of, calldata.span());
        if (result.is_err()) {
            result = call_contract_syscall(token, selector_for_balanceOf, calldata.span());
        }
        u256_from_felt252(*result.unwrap_syscall().at(0))
    }
}
