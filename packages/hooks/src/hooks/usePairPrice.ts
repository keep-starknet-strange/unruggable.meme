import { getPairPrice } from 'core'
import { BlockNumber, BlockTag } from 'starknet'

import { Pair } from '../types'
import { useQuery } from './internal/useQuery'
import { useFactory } from './useFactory'

export const usePairPrice = (pair?: Pair, blockNumber: BlockNumber = BlockTag.latest) => {
  const factory = useFactory()

  return useQuery({
    queryKey: ['pairPrice', pair?.address, pair?.reversed],
    queryFn: async () => {
      if (!pair) return
      return getPairPrice(factory.config.provider, pair, blockNumber)
    },
    enabled: !!pair,
  })
}
