import { Fraction } from '@uniswap/sdk-core'
import { BlockNumber, BlockTag } from 'starknet'

import { usePairPrice } from './usePairPrice'
import { useQuoteToken } from './useQuoteToken'

export function useQuoteTokenPrice(address?: string, blockNumber: BlockNumber = BlockTag.latest) {
  const quoteToken = useQuoteToken(address)
  const pairPrice = usePairPrice(quoteToken?.usdcPair, blockNumber)

  if (!quoteToken) return
  if (!quoteToken.usdcPair) return new Fraction(1, 1)

  return pairPrice.data
}
