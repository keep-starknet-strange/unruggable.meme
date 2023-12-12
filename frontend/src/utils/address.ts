import { validateAndParseAddress } from 'starknet'

export function shortenL2Address(address: string, chars = 4): string {
  try {
    const parsed = validateAndParseAddress(address)
    return `${parsed.substring(0, chars + 2)}...${parsed.substring(66 - chars)}`
  } catch {
    throw Error(`Invalid 'address' parameter '${address}'.`)
  }
}
