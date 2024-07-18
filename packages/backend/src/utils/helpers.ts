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
