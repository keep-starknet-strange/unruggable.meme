mod errors;

mod factory;

#[cfg(test)]
mod tests;
mod token_locker;

mod tokens;

mod mocks {
    mod erc20;
    mod jediswap {
        mod factory;
        mod pair;
        mod router;
    }
}

mod amm {
    mod amm;
    mod jediswap_interface;
}
