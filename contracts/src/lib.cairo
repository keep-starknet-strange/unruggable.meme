mod errors;

#[cfg(test)]
mod tests;
mod token_locker;

mod tokens {
    mod erc20;
    mod factory;
    mod interface;
    mod memecoin;
}

mod amm {
    mod amm;
    mod jediswap_interface;
}

mod tests_utils {
    mod deployer_helper;
    mod jediswap {
        mod factory;
        mod pair;
        mod router;
    }
}
