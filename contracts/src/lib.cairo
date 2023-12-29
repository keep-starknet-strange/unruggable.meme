mod errors;
mod locker;
mod tokens;
mod factory;

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

#[cfg(test)]
mod tests;
