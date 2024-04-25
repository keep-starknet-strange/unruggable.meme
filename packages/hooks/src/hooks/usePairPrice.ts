import { useProvider } from '@starknet-react/core'
import { UseQueryResult } from '@tanstack/react-query'
import { Fraction } from '@uniswap/sdk-core'
import { getPairPrice } from 'core'
import { BlockNumber, BlockTag } from 'starknet'

import { Pair } from '../types'
import { useQuery } from './internal/useQuery'

export function usePairPrice(
  pair?: Pair,
  blockNumber: BlockNumber = BlockTag.latest,
): UseQueryResult<Fraction | undefined, Error | null> {
  const { provider } = useProvider()

  return useQuery({
    queryKey: ['pairPrice', pair?.address, pair?.reversed],
    queryFn: async () => {
      if (!pair) return

      // tsup somehow complains about the type of the blockNumber
      return getPairPrice(provider, pair, blockNumber as BlockTag)
    },
    enabled: !!pair,
  })
}
