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

fn unique_count<T, +Copy<T>, +Drop<T>, +PartialEq<T>, +Into<T, felt252>>(mut self: Span<T>) -> u32 {
    let mut dict: Felt252Dict<felt252> = Default::default();
    let mut counter = 0;
    loop {
        match self.pop_front() {
            Option::Some(value) => {
                let value: felt252 = (*value).into();
                if dict.get(value).is_one() {
                    continue;
                }
                dict.insert(value, One::one());
                counter += 1;
            },
            Option::None => { break; }
        }
    };
    counter
}
