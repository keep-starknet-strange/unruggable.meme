import { Fraction } from '@uniswap/sdk-core'
import { useCallback } from 'react'

export function useWeiAmountToParsedFiatValue(price?: Fraction): (amount?: Fraction) => string | null {
  return useCallback(
    (amount?: Fraction) =>
      price && amount
        ? `$${(Math.round(+amount.multiply(price).toFixed(6) * 100) / 100).toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}`
        : null,
    [price],
  )
}
