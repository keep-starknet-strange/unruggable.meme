import { constants } from 'core'

import { useFactory } from './internal/useFactory'

export const useQuoteToken = (address: string) => {
  const factory = useFactory()

  return constants.QUOTE_TOKENS[factory.config.chainId][address]
}
