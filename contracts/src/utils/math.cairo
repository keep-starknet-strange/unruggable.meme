const BPS: u256 = 10_000; // 100% = 10_000 bps

trait PercentageMath {
    fn percent_mul(self: u256, other: u256) -> u256;
}

impl PercentageMathImpl of PercentageMath {
    fn percent_mul(self: u256, other: u256) -> u256 {
        self * other / BPS
    }
}

fn pow_64(self: u64, mut exponent: u8) -> u64 {
    if self.is_zero() {
        return 0;
    }
    let mut result = 1;
    let mut base = self;

    loop {
        if exponent & 1 == 1 {
            result = result * base;
        }

        exponent = exponent / 2;
        if exponent == 0 {
            break result;
        }

        base = base * base;
    }
}