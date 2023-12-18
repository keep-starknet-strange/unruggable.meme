import { validateAndParseAddress } from 'starknet'

export function shortenL2Address(address: string, chars = 4): string {
  try {
    const parsed = validateAndParseAddress(address)
    return `${parsed.substring(0, chars + 2)}...${parsed.substring(66 - chars)}`
  } catch {
    throw Error(`Invalid 'address' parameter '${address}'.`)
  }
}

export function isValidL2Address(address: string): boolean {
  // Wallets like to omit leading zeroes, so we cannot check for a fixed length.
  // On the other hand, we don't want users to mistakenly enter an Ethereum address.
  return /^0x[0-9a-fA-F]{50,64}$/.test(address)
}
