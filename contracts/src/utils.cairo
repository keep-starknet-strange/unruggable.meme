mod math;
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
