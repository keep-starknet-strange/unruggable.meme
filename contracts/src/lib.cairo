mod errors;
mod exchanges;
mod factory;
mod locker;

mod token;

mod utils;

mod mocks {
    mod erc20;
    mod jediswap {
        mod factory;
        mod pair;
        mod router;
    }
    mod ekubo {
        mod swapper;
    }
}
#[cfg(test)]
mod tests;
