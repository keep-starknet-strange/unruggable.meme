import { constants } from 'core'
import { getChecksumAddress } from 'starknet'

import { useFactory } from './useFactory'

export const useQuoteToken = (address: string) => {
  const factory = useFactory()

  if (!address) return

  return constants.QUOTE_TOKENS[factory.config.chainId][getChecksumAddress(address)]
}
