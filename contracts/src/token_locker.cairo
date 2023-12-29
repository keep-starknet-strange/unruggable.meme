use starknet::ContractAddress;

#[starknet::interface]
trait ITokenLocker<TContractState> {
    fn lock(ref self: TContractState, token_contract: ContractAddress, amount: u256);
    fn unlock(ref self: TContractState, token_contract: ContractAddress, lock_timestamp: u64);
    fn get_locked_amount(
        self: @TContractState,
        token_contract: ContractAddress,
        owner: ContractAddress,
        lock_timestamp: u64
    ) -> u256;
    fn get_time_left(
        self: @TContractState,
        token_contract: ContractAddress,
        owner: ContractAddress,
        lock_timestamp: u64
    ) -> u64;
}

#[starknet::contract]
mod TokenLocker {
    use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_contract_address, get_block_timestamp};
    use unruggable::errors::{
        ZERO_LOCK, ZERO_LOCK_TIME, LOCK_EXIST, TRANSFER_FAIL, LOCK_NONEXIST, STILL_LOCKED
    };

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TokenLocked: TokenLocked,
        TokenUnlocked: TokenUnlocked
    }

    #[derive(Drop, starknet::Event)]
    struct TokenLocked {
        locker: ContractAddress,
        token: ContractAddress,
        lock_timestamp: u64,
        amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct TokenUnlocked {
        unlocker: ContractAddress,
        token: ContractAddress,
        unlock_timestamp: u64,
        amount: u256
    }

    #[storage]
    struct Storage {
        lock_time: u64,
        locks: LegacyMap<(ContractAddress, ContractAddress, u64), u256>,
    }

    /// Constructor called once when the contract is deployed.
    /// # Arguments
    /// * `lock_time` - Locking period as timestamp.
    #[constructor]
    fn constructor(ref self: ContractState, lock_time: u64) {
        self.lock_time.write(lock_time);
    }

    #[abi(embed_v0)]
    impl TokenLocker of super::ITokenLocker<ContractState> {
        /// Locks tokens from callers account
        /// # Arguments
        /// * `token_contract` - Address of token contract that is going to be locked
        /// * `amount` - Amount of tokens that is going to be locked
        fn lock(ref self: ContractState, token_contract: ContractAddress, amount: u256) {
            assert(amount != 0, ZERO_LOCK);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            assert(self.locks.read((token_contract, caller, current_time)) == 0, LOCK_EXIST);

            self.locks.write((token_contract, caller, current_time), amount);

            let this_address = get_contract_address();
            let erc20_dispatcher = ERC20ABIDispatcher { contract_address: token_contract };
            let initial_balance = erc20_dispatcher.balanceOf(this_address);
            erc20_dispatcher.transferFrom(caller, this_address, amount);
            assert(erc20_dispatcher.balanceOf(this_address) - initial_balance == amount, TRANSFER_FAIL);

            self
                .emit(
                    TokenLocked {
                        locker: caller,
                        token: token_contract,
                        lock_timestamp: current_time,
                        amount: amount
                    }
                );
        }

        /// Unlocks tokens to callers account
        /// # Arguments
        /// * `token_contract` - Address of token contract that is going to be unlocked
        /// * `lock_timestamp` - Initial lock timestamp
        fn unlock(ref self: ContractState, token_contract: ContractAddress, lock_timestamp: u64) {
            assert(lock_timestamp != 0, ZERO_LOCK_TIME);

            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            let locked_amount = self.locks.read((token_contract, caller, lock_timestamp));

            assert(locked_amount != 0, LOCK_NONEXIST);
            let lock_end_time = lock_timestamp + self.lock_time.read();

            assert(current_time >= lock_end_time, STILL_LOCKED);

            self.locks.write((token_contract, caller, lock_timestamp), 0);

            let erc20_dispatcher = ERC20ABIDispatcher { contract_address: token_contract };
            let initial_balance = erc20_dispatcher.balanceOf(caller);
            erc20_dispatcher.transfer(caller, locked_amount);
            assert(erc20_dispatcher.balanceOf(caller) - initial_balance == locked_amount, TRANSFER_FAIL);

            self
                .emit(
                    TokenUnlocked {
                        unlocker: caller,
                        token: token_contract,
                        unlock_timestamp: current_time,
                        amount: locked_amount
                    }
                );
        }

        /// View method for locked amount
        /// # Arguments
        /// * `token_contract` - Address of token contract
        /// * `owner` - Address of the owner of the token
        /// * `lock_timestamp` - Initial lock timestamp
        /// # Returns
        /// Locked amount
        fn get_locked_amount(
            self: @ContractState,
            token_contract: ContractAddress,
            owner: ContractAddress,
            lock_timestamp: u64
        ) -> u256 {
            self.locks.read((token_contract, owner, lock_timestamp))
        }

        /// View method for time left to unlock
        /// # Arguments
        /// * `token_contract` - Address of token contract
        /// * `owner` - Address of the owner of the token
        /// * `lock_timestamp` - Initial lock timestamp
        /// # Returns
        /// Time left to unlock
        fn get_time_left(
            self: @ContractState,
            token_contract: ContractAddress,
            owner: ContractAddress,
            lock_timestamp: u64
        ) -> u64 {
            let locked_amount = self.locks.read((token_contract, owner, lock_timestamp));
            if (locked_amount == 0) {
                return 0_u64;
            }

            let lock_end_time = lock_timestamp + self.lock_time.read();
            let current_time = get_block_timestamp();
            if (current_time >= lock_end_time) {
                return 0_u64;
            }

            lock_end_time - current_time
        }
    }
}
