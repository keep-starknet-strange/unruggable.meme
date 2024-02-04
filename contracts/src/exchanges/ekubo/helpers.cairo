use ekubo::types::bounds::Bounds;
use ekubo::types::i129::i129;

/// Calculates the initial tick and bounds for a liquidity pool from the starting price and the magnitude of the single bound delimiting the range [starting_price, upper_bound] or [lower_bound, starting_price].
///
/// # Arguments
///
/// * `starting_price` - The initial price of the token pair.
/// * `bound_mag` - The magintude of bound.
/// * `is_token1_quote` - A boolean indicating whether token1 is the quote currency.
///
/// # Returns
///
/// * A tuple containing the initial tick and the bounds.
///
/// If `is_token1_quote` is true, the initial tick and lower bound are set to the starting price,
/// and the upper bound is set to the provided bound as a positive integer.
///
/// If `is_token1_quote` is false, the initial tick and upper bound are set to the negative of the starting price,
/// and the lower bound is set to the provided bound as a negative integer.
///
/// The sign of the initial tick is reversed if the quote is token0, as the price provided was expressed in token1/token0.
///
fn get_initial_tick_from_starting_price(
    starting_price: i129, bound_mag: u128, is_token1_quote: bool
) -> (i129, Bounds) {
    let (initial_tick, bounds) = if is_token1_quote {
        // the price is always supplied in quote/meme. if token 1 is quote,
        // then the upper bound expressed in quote/meme is +inf
        // and the lower bound is the starting price.
        (
            i129 { sign: starting_price.sign, mag: starting_price.mag },
            Bounds {
                lower: i129 { sign: starting_price.sign, mag: starting_price.mag },
                upper: i129 { sign: false, mag: bound_mag }
            }
        )
    } else {
        // The initial tick sign is reversed if the quote is token0.
        // as the price provided was expressed in token1/token0.
        (
            i129 { sign: !starting_price.sign, mag: starting_price.mag },
            Bounds {
                lower: i129 { sign: true, mag: bound_mag },
                upper: i129 { sign: !starting_price.sign, mag: starting_price.mag }
            }
        )
    };
    (initial_tick, bounds)
}


fn get_next_tick_bounds(starting_price: i129, tick_spacing: u128, is_token1_quote: bool) -> Bounds {
    // The sign of the next bound is the same as the sign of the starting tick.
    // If the token1 is the quote token, the price is expressed in the correct token1/token 0 order
    // and the sign of the starting tick is the same as the sign of the price.
    // otherwise, it's flipped.
    let bound_sign = if is_token1_quote {
        starting_price.sign
    } else {
        !starting_price.sign
    };

    // The magnitude of the next bound is the starting tick magnitude plus or minus the tick spacing.
    // If the starting sign is negative, then the next bound is the starting tick minus the tick spacing.
    // If the starting sign is positive, then the next bound is the starting tick plus the tick spacing.
    let bound_mag = if starting_price.sign {
        starting_price.mag - tick_spacing
    } else {
        starting_price.mag + tick_spacing
    };

    let (lower_mag, upper_mag) = if (is_token1_quote) {
        (starting_price.mag, bound_mag)
    } else {
        (bound_mag, starting_price.mag)
    };

    Bounds {
        lower: i129 { sign: bound_sign, mag: lower_mag },
        upper: i129 { sign: bound_sign, mag: upper_mag }
    }
}
