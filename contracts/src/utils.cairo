mod math;
use core::num::traits::{One};
use integer::u256_from_felt252;
use starknet::ContractAddress;

// Allows comparing contract addresses as if they are integers
impl ContractAddressOrder of PartialOrd<ContractAddress> {
    #[inline(always)]
    fn le(lhs: ContractAddress, rhs: ContractAddress) -> bool {
        u256_from_felt252(lhs.into()) <= u256_from_felt252(rhs.into())
    }
    #[inline(always)]
    fn ge(lhs: ContractAddress, rhs: ContractAddress) -> bool {
        u256_from_felt252(lhs.into()) >= u256_from_felt252(rhs.into())
    }

    #[inline(always)]
    fn lt(lhs: ContractAddress, rhs: ContractAddress) -> bool {
        u256_from_felt252(lhs.into()) < u256_from_felt252(rhs.into())
    }
    #[inline(always)]
    fn gt(lhs: ContractAddress, rhs: ContractAddress) -> bool {
        u256_from_felt252(lhs.into()) > u256_from_felt252(rhs.into())
    }
}

fn unique_count<T, +Copy<T>, +Drop<T>, +PartialEq<T>>(mut self: Span<T>) -> u32 {
    let mut counter = 0;
    let mut result: Array<T> = array![];
    loop {
        match self.pop_front() {
            Option::Some(value) => {
                if contains(result.span(), *value) {
                    continue;
                }
                result.append(*value);
                counter += 1;
            },
            Option::None => { break; }
        }
    };
    counter
}

fn contains<T, +Copy<T>, +Drop<T>, +PartialEq<T>>(mut self: Span<T>, value: T) -> bool {
    loop {
        match self.pop_front() {
            Option::Some(current) => { if *current == value {
                break true;
            } },
            Option::None => { break false; }
        }
    }
}
