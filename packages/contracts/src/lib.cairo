mod errors;
mod exchanges;
mod factory;
mod locker;
#[cfg(test)]
mod tests;

mod token;

mod utils;

mod mocks {
    mod erc20;
    mod jediswap {
        mod factory;
        mod pair;
        mod router;
    }
}
