use ekubo::types::i129::i129;
use ekubo::types::bounds::Bounds;

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


/// Calculates the next tick bounds based on the starting tick, tick spacing, and whether token1 is the quote token.
///
/// The starting tick is always expressed in terms of MEME/QUOTE. The conversion is done internally to the contract.
/// The bounds are calculated differently depending on whether token1 is the quote token and whether the starting tick is positive or negative.
///
/// If token1 is the quote token and the starting tick is negative, buying makes the price go up,
/// so the upper bound is the starting tick - tick spacing and the lower bound is the starting tick.
///
/// If token1 is the quote token and the starting tick is positive, buying makes the price go down.
/// so the lower bound is the starting tick - tick spacing and the upper bound is the starting tick.
///
/// If token1 is not the quote token and the starting tick is negative, buying makes the price go down.
/// so the lower bound is the starting tick and the upper bound is the starting tick + tick spacing.

/// If token1 is not the quote token and the starting tick is negative, buying makes the price go up.
/// so the upper bound is the starting tick + tick spacing and the lower bound is the starting tick.
///
/// # Arguments
///
/// * `starting_price` - The starting tick.
/// * `tick_spacing` - The spacing between ticks.
/// * `is_token1_quote` - Whether token1 is the quote token.
///
/// # Returns
///
/// * `Bounds` - The lower and upper bounds for the next tick.
///
fn get_next_tick_bounds(starting_price: i129, tick_spacing: u128, is_token1_quote: bool) -> Bounds {
    if is_token1_quote {
        if starting_price.sign {
            // Case 1 -> price meme/quote > 0, pool price < 0, buying makes price go up
            Bounds {
                lower: i129 { sign: true, mag: starting_price.mag },
                upper: i129 { sign: true, mag: starting_price.mag - tick_spacing }
            }
        // Case 2 -> price meme/quote < 0, pool price > 0, buying makes price go down
        } else {
            // Case 2 -> price meme/quote < 0, pool price > 0, buying makes price go down
            Bounds {
                lower: i129 { sign: false, mag: starting_price.mag - tick_spacing },
                upper: i129 { sign: false, mag: starting_price.mag }
            }
        }
    } else {
        if starting_price.sign {
            // Case 3 -> price meme/quote < 0, pool price < 0, buying makes price go down
            Bounds {
                lower: i129 { sign: true, mag: starting_price.mag + tick_spacing },
                upper: i129 { sign: true, mag: starting_price.mag }
            }
        } else {
            // Case 4 -> price meme/quote > 0, pool price > 0, buying makes price go up
            Bounds {
                lower: i129 { sign: false, mag: starting_price.mag },
                upper: i129 { sign: false, mag: starting_price.mag + tick_spacing }
            }
        }
    }
}
