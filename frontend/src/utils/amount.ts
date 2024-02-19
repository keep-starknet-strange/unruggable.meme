import { Fraction, Percent } from '@uniswap/sdk-core'
import { PERCENTAGE_INPUT_PRECISION } from 'src/constants/misc'

export const parseFormatedAmount = (amount: string) => amount.replace(/,/g, '')

export const parseFormatedPercentage = (percent: string) =>
  new Percent(+percent * 10 ** PERCENTAGE_INPUT_PRECISION, 100 * 10 ** PERCENTAGE_INPUT_PRECISION)

interface ParseCurrencyAmountOptions {
  fixed: number
  significant?: number
}

export const formatCurrenyAmount = (amount: Fraction, { fixed, significant = 1 }: ParseCurrencyAmountOptions) => {
  const fixedAmount = amount.toFixed(fixed)
  const significantAmount = amount.toSignificant(significant)

  if (+significantAmount > +fixedAmount) return significantAmount
  else return +fixedAmount.toString()
}

export const formatPercentage = (percentage: Percent) => {
  const formatedPercentage = +percentage.toFixed(2)
  const exact = percentage.equalTo(new Percent(Math.round(formatedPercentage * 100), 10000))

  return `${exact ? '' : '~'}${formatedPercentage}%`
}
