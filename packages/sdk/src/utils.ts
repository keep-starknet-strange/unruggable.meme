import { Percent } from '@uniswap/sdk-core'
import { PERCENTAGE_INPUT_PRECISION } from './constants'

export const convertPercentageStringToPercent = (percentString: string): Percent => {
  const precisionMultiplier = 10 ** PERCENTAGE_INPUT_PRECISION
  return new Percent(+percentString * precisionMultiplier, 100 * precisionMultiplier)
}

export const normalizeAmountString = (amountString: string): string => amountString.replace(/,/g, '')

export function validateStarknetAddress(address: string): boolean {
  // Wallets like to omit leading zeroes, so we cannot check for a fixed length.
  // On the other hand, we don't want users to mistakenly enter an Ethereum address.
  return /^0x[0-9a-fA-F]{50,64}$/.test(address)
}
