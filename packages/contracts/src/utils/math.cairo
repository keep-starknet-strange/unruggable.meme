const BPS: u256 = 10_000; // 100% = 10_000 bps

trait PercentageMath {
    fn percent_mul(self: u256, other: u256) -> u256;
}

impl PercentageMathImpl of PercentageMath {
    fn percent_mul(self: u256, other: u256) -> u256 {
        self * other / BPS
    }
}
