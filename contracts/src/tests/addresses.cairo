//! A registry of onchain addresses used for tests. These address match the ones deployed on
//! Starknet mainnet unless indicated otherwise.

use starknet::ContractAddress;


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
