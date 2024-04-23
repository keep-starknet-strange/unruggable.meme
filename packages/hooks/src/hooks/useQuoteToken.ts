import { QUOTE_TOKENS } from 'core/constants'
import { getChecksumAddress } from 'starknet'

import { useFactory } from './useFactory'

export const useQuoteToken = (address: string) => {
  const factory = useFactory()

  if (!address) return

  return QUOTE_TOKENS[factory.config.chainId][getChecksumAddress(address)]
}
