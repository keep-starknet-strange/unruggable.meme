import { getPairPrice } from 'core'
import { BlockTag } from 'starknet'

import { Pair } from '../types'
import { useQuery } from './internal/useQuery'
import { useFactory } from './useFactory'

export const usePairPrice = (pair?: Pair, blockNumber = BlockTag.latest) => {
  const factory = useFactory()

  return useQuery({
    queryKey: ['pairPrice', pair?.address, pair?.reversed],
    queryFn: async () => {
      if (!pair) return
      return getPairPrice(factory.config, pair, blockNumber)
    },
    enabled: !!pair,
  })
}
