// @title JediSwap Factory Cairo 1.0
// @author Mesh Finance
// @license MIT
// @notice Factory to create and register new pairs

use starknet::ContractAddress;
use starknet::ClassHash;

#[starknet::interface]
trait IFactoryC1<TContractState> {
    // view functions
    fn get_pair(
        self: @TContractState, token0: ContractAddress, token1: ContractAddress
    ) -> ContractAddress;
    fn get_all_pairs(self: @TContractState) -> (u32, Array::<ContractAddress>);
    fn get_num_of_pairs(self: @TContractState) -> u32;
    fn get_fee_to(self: @TContractState) -> ContractAddress;
    fn get_fee_to_setter(self: @TContractState) -> ContractAddress;
    fn get_pair_contract_class_hash(self: @TContractState) -> ClassHash;
    // external functions
    fn create_pair(
        ref self: TContractState, tokenA: ContractAddress, tokenB: ContractAddress
    ) -> ContractAddress;
    fn set_fee_to(ref self: TContractState, new_fee_to: ContractAddress);
    fn set_fee_to_setter(ref self: TContractState, new_fee_to_setter: ContractAddress);
    fn replace_implementation_class(ref self: TContractState, new_implementation_class: ClassHash);
    fn replace_pair_contract_hash(ref self: TContractState, new_pair_contract_class: ClassHash);
}

#[starknet::contract]
mod FactoryC1 {
    use array::ArrayTrait;
    use zeroable::Zeroable;
    use starknet::{
        ContractAddress, ClassHash, SyscallResult, SyscallResultTrait, get_caller_address,
        contract_address_const, contract_address_to_felt252
    };
    use starknet::class_hash::class_hash_to_felt252;
    use integer::u256_from_felt252;
    use starknet::syscalls::{deploy_syscall, replace_class_syscall};
    use poseidon::poseidon_hash_span;


    //
    // Storage
    //
    #[storage]
    struct Storage {
        _fee_to: ContractAddress, // @dev Address of fee recipient
        _fee_to_setter: ContractAddress, // @dev Address allowed to change feeTo.
        _all_pairs: LegacyMap::<u32, ContractAddress>, // @dev Array of all pairs
        _pair: LegacyMap::<
            (ContractAddress, ContractAddress), ContractAddress
        >, // @dev Pair address for pair of `token0` and `token1`
        _num_of_pairs: u32, // @dev Total pairs
        _pair_contract_class_hash: ClassHash,
        Proxy_admin: ContractAddress, // @dev Admin contract address, to be used till we finalize Cairo upgrades.
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        PairCreated: PairCreated,
    }

    // @dev Emitted each time a pair is created via create_pair
    // token0 is guaranteed to be strictly less than token1 by sort order.
    #[derive(Drop, starknet::Event)]
    struct PairCreated {
        token0: ContractAddress,
        token1: ContractAddress,
        pair: ContractAddress,
        total_pairs: u32
    }

    //
    // Constructor
    //

    // @notice Contract constructor
    // @param fee_to_setter Fee Recipient Setter
    #[constructor]
    fn constructor(
        ref self: ContractState, pair_contract_class_hash: ClassHash, fee_to_setter: ContractAddress
    ) {
        assert(!fee_to_setter.is_zero(), 'can not be zero');

        assert(!pair_contract_class_hash.is_zero(), 'can not be zero');

        self._fee_to_setter.write(fee_to_setter);
        self._pair_contract_class_hash.write(pair_contract_class_hash);
        self._num_of_pairs.write(0);
    }

    #[external(v0)]
    impl FactoryC1 of super::IFactoryC1<ContractState> {
        //
        // Getters
        //

        // @notice Get pair address for the pair of `token0` and `token1`
        // @param token0 Address of token0
        // @param token1 Address of token1
        // @return pair Address of the pair
        fn get_pair(
            self: @ContractState, token0: ContractAddress, token1: ContractAddress
        ) -> ContractAddress {
            let pair_0_1 = self._pair.read((token0, token1));
            if (pair_0_1 == contract_address_const::<0>()) {
                let pair_1_0 = self._pair.read((token1, token0));
                return pair_1_0;
            } else {
                return pair_0_1;
            }
        }

        // @notice Get all the pairs registered
        // @return all_pairs_len Length of `all_pairs` array
        // @return all_pairs Array of addresses of the registered pairs
        fn get_all_pairs(
            self: @ContractState
        ) -> (u32, Array::<ContractAddress>) { //Array::<ContractAddress>
            let mut all_pairs_array = ArrayTrait::<ContractAddress>::new();
            let num_pairs = self._num_of_pairs.read();
            let mut current_index = 0;
            loop {
                if current_index == num_pairs {
                    break true;
                }
                all_pairs_array.append(self._all_pairs.read(current_index));
                current_index += 1;
            };
            (num_pairs, all_pairs_array)
        }

        // @notice Get the number of pairs
        // @return num_of_pairs
        fn get_num_of_pairs(self: @ContractState) -> u32 {
            self._num_of_pairs.read()
        }

        // @notice Get fee recipient address
        // @return address
        fn get_fee_to(self: @ContractState) -> ContractAddress {
            self._fee_to.read()
        }

        // @notice Get the address allowed to change fee_to.
        // @return address
        fn get_fee_to_setter(self: @ContractState) -> ContractAddress {
            self._fee_to_setter.read()
        }

        // @notice Get the class hash of the Pair contract which is deployed for each pair.
        // @return class_hash
        fn get_pair_contract_class_hash(self: @ContractState) -> ClassHash {
            self._pair_contract_class_hash.read()
        }

        //
        // Setters
        //

        // @notice Create pair of `tokenA` and `tokenB` with deterministic address using deploy
        // @dev tokens are sorted before creating pair.
        // @param tokenA Address of tokenA
        // @param tokenB Address of tokenB
        // @return pair Address of the created pair
        fn create_pair(
            ref self: ContractState, tokenA: ContractAddress, tokenB: ContractAddress
        ) -> ContractAddress {
            assert(!tokenA.is_zero() & !tokenB.is_zero(), 'must be non zero');

            assert(tokenA != tokenB, 'must be different');

            let existing_pair = FactoryC1::get_pair(@self, tokenA, tokenB);
            assert(existing_pair.is_zero(), 'pair already exists');

            let pair_contract_class_hash = self._pair_contract_class_hash.read();
            let (token0, token1) = _sort_tokens(tokenA, tokenB);
            let mut hash_data: Array<felt252> = ArrayTrait::new();
            Serde::serialize(@token0, ref hash_data);
            Serde::serialize(@token1, ref hash_data);
            let salt = poseidon_hash_span(hash_data.span());

            let mut constructor_calldata = Default::default();
            Serde::serialize(@token0, ref constructor_calldata);
            Serde::serialize(@token1, ref constructor_calldata);

            let syscall_result = deploy_syscall(
                pair_contract_class_hash, salt, constructor_calldata.span(), false
            );
            let (pair, _) = syscall_result.unwrap_syscall();

            self._pair.write((token0, token1), pair);
            let num_pairs = self._num_of_pairs.read();
            self._all_pairs.write(num_pairs, pair);
            self._num_of_pairs.write(num_pairs + 1);
            self
                .emit(
                    PairCreated {
                        token0: token0, token1: token1, pair: pair, total_pairs: num_pairs + 1
                    }
                );

            pair
        }

        // @notice Change fee recipient to `new_fee_to`
        // @dev Only fee_to_setter can change
        // @param fee_to Address of new fee recipient
        fn set_fee_to(ref self: ContractState, new_fee_to: ContractAddress) {
            let sender = get_caller_address();
            let fee_to_setter = FactoryC1::get_fee_to_setter(@self);
            assert(sender == fee_to_setter, 'must be fee to setter');
            self._fee_to.write(new_fee_to);
        }

        // @notice Change fee setter to `fee_to_setter`
        // @dev Only fee_to_setter can change
        // @param fee_to_setter Address of new fee setter
        fn set_fee_to_setter(ref self: ContractState, new_fee_to_setter: ContractAddress) {
            let sender = get_caller_address();
            let fee_to_setter = FactoryC1::get_fee_to_setter(@self);
            assert(sender == fee_to_setter, 'must be fee to setter');
            assert(!new_fee_to_setter.is_zero(), 'must be non zero');
            self._fee_to_setter.write(new_fee_to_setter);
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

        // @notice This replaces _pair_contract_class_hash used to deploy new pairs
        // @dev Only Proxy_admin can call
        // @param new_pair_contract_class New _pair_contract_class_hash
        fn replace_pair_contract_hash(ref self: ContractState, new_pair_contract_class: ClassHash) {
            let sender = get_caller_address();
            let proxy_admin = self.Proxy_admin.read();
            assert(sender == proxy_admin, 'must be admin');
            assert(!new_pair_contract_class.is_zero(), 'must be non zero');
            self._pair_contract_class_hash.write(new_pair_contract_class);
        }
    }

    //
    // Internals LIBRARY
    //

    fn _sort_tokens(
        tokenA: ContractAddress, tokenB: ContractAddress
    ) -> (ContractAddress, ContractAddress) {
        assert(tokenA != tokenB, 'must not be identical');
        let mut token0 = contract_address_const::<0>();
        let mut token1 = contract_address_const::<0>();
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
}
