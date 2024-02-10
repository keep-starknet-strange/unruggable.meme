import { Fraction, Percent } from '@uniswap/sdk-core'

export const parseFormatedAmount = (amount: string) => amount.replace(/,/g, '')

interface ParseCurrencyAmountOptions {
  fixed: number
  significant?: number
}

export const formatCurrenyAmount = (amount: Fraction, { fixed, significant = 1 }: ParseCurrencyAmountOptions) =>
  Math.max(+amount.toFixed(fixed), +amount.toSignificant(significant))

export const formatPercentage = (percentage: Percent) => {
  const formatedPercentage = +percentage.toFixed(2)
  const exact = percentage.equalTo(new Percent(Math.round(formatedPercentage * 100), 10000))

  return `${exact ? '' : '~'}${formatedPercentage}%`
}
