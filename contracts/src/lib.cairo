mod errors;
mod factory;
mod locker;

#[cfg(test)]
mod tests;
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
