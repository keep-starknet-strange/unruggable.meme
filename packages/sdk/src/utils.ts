import { Percent } from '@uniswap/sdk-core'

export const PERCENTAGE_INPUT_PRECISION = 2

export const parseFormatedPercentage = (percent: string) =>
  new Percent(+percent * 10 ** PERCENTAGE_INPUT_PRECISION, 100 * 10 ** PERCENTAGE_INPUT_PRECISION)

export const parseFormatedAmount = (amount: string) => amount.replace(/,/g, '')

export function isValidL2Address(address: string): boolean {
  // Wallets like to omit leading zeroes, so we cannot check for a fixed length.
  // On the other hand, we don't want users to mistakenly enter an Ethereum address.
  return /^0x[0-9a-fA-F]{50,64}$/.test(address)
}
