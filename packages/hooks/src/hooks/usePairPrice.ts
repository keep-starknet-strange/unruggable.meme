import { useProvider } from '@starknet-react/core'
import { UseQueryResult } from '@tanstack/react-query'
import { Fraction } from '@uniswap/sdk-core'
import { getPairPrice } from 'core'
import { BlockNumber, BlockTag } from 'starknet'

import { Pair, UseQueryProps } from '../types'
import { useQuery } from './internal/useQuery'

export type UsePairPriceProps = UseQueryProps & {
  pair?: Pair
  blockNumber?: BlockNumber
}

export function usePairPrice({
  pair,
  blockNumber = BlockTag.latest,
  ...props
}: UsePairPriceProps): UseQueryResult<Fraction | undefined, Error | null> {
  const { provider } = useProvider()

  return useQuery({
    queryKey: ['pairPrice', pair?.address, pair?.reversed],
    queryFn: async () => {
      if (!pair) return

      return await getPairPrice(provider, pair, blockNumber)
    },
    enabled: Boolean(pair),
    ...props,
  })
}
