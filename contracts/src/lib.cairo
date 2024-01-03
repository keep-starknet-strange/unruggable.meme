mod errors;
mod exchanges;
mod factory;
mod locker;

#[cfg(test)]
mod tests;
mod tokens;

mod utils {
    mod math;
}

mod mocks {
    mod erc20;
    mod jediswap {
        mod factory;
        mod pair;
        mod router;
    }
    mod ekubo{
        mod swapper;
    }
}
