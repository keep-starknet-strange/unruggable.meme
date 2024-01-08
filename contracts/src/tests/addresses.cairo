use core::traits::TryInto;
//! A registry of onchain addresses used for tests. These address match the ones deployed on
//! Starknet mainnet unless indicated otherwise.

use starknet::{ClassHash, ContractAddress};


fn JEDI_ROUTER_ADDRESS() -> ContractAddress {
    0x041fd22b238fa21cfcf5dd45a8548974d8263b3a531a60388411c5e230f97023.try_into().unwrap()
}

fn JEDI_FACTORY_ADDRESS() -> ContractAddress {
    0x00dad44c139a476c7a17fc8141e6db680e9abc9f56fe249a105094c44382c2fd.try_into().unwrap()
}

// NOT THE ACTUAL ETH ADDRESS
// It's set to a the maximum possible value for a contract address
// This ensures that in Jediswap pairs, the ETH side is always token1
fn ETH_ADDRESS() -> ContractAddress {
    0x7fff6570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7.try_into().unwrap()
}

// A helper that returns a very small address, ensuring that this token is always token0 in a pair
fn TOKEN0_ADDRESS() -> ContractAddress {
    0x00000000000000000000000000000000000000000000000000000000000000A.try_into().unwrap()
}

fn EKUBO_CORE() -> ContractAddress {
    0x00000005dd3d2f4429af886cd1a3b08289dbcea99a294197e9eb43b0e0325b4b.try_into().unwrap()
}

fn EKUBO_POSITIONS() -> ContractAddress {
    0x02e0af29598b407c8716b17f6d2795eca1b471413fa03fb145a5e33722184067.try_into().unwrap()
}

fn EKUBO_REGISTRY() -> ContractAddress {
    0x006f55e718ae592b22117c3e3b557b6b2b5f827ddcd7e6fdebd1a4ce7462c93e.try_into().unwrap()
}

fn EKUBO_NFT_CLASS_HASH() -> ClassHash {
    0x034a6f8fbc43c018805c0d73486f7c8e819c12116e6fbaf846e58b9b8b63c27e.try_into().unwrap()
}
