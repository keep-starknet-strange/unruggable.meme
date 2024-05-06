import { Percent } from '@uniswap/sdk-core'

import { PERCENTAGE_INPUT_PRECISION } from './constants'

/**
 * Checks if a given string is a valid StarkNet address.
 *
 * A valid StarkNet address must start with '0x' followed by 63 or 64 hexadecimal characters.
 *
 * @param address - The string to be tested against the StarkNet address format.
 * @returns `true` if the string is a valid StarkNet address, otherwise `false`.
 */
export function isValidStarknetAddress(address: string): boolean {
  const regex = /^0x[0-9a-fA-F]{50,64}$/
  return regex.test(address)
}

export const decimalsScale = (decimals: number) => `1${Array(decimals).fill('0').join('')}`

export const formatPercentage = (percentage: Percent) => {
  const formatedPercentage = +percentage.toFixed(2)
  const exact = percentage.equalTo(new Percent(Math.round(formatedPercentage * 100), 10000))

  return `${exact ? '' : '~'}${formatedPercentage}%`
}

export const parsePercentage = (percentage: string | number) =>
  new Percent(+percentage * 10 ** PERCENTAGE_INPUT_PRECISION, 100 * 10 ** PERCENTAGE_INPUT_PRECISION)
