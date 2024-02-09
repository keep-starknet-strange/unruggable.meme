import { Fraction } from '@uniswap/sdk-core'

export const parseFormatedAmount = (amount: string) => amount.replace(/,/g, '')

interface ParseCurrencyAmountOptions {
  fixed: number
  significant?: number
}

export const parseCurrencyAmount = (amount: Fraction, { fixed, significant = 1 }: ParseCurrencyAmountOptions) =>
  Math.max(+amount.toFixed(fixed), +amount.toSignificant(significant))
