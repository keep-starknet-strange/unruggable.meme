import { useProvider } from '@starknet-react/core'
import { Fraction } from '@uniswap/sdk-core'
import { getPairPrice } from 'core'
import { BlockNumber } from 'starknet'

import { UseQueryProps } from '../types'
import { useQuery } from './internal/useQuery'
import { useQuoteToken } from './useQuoteToken'

export type UseQuoteTokenPriceProps = UseQueryProps & {
  address?: string
  blockNumber?: BlockNumber
}

export function useQuoteTokenPrice({ address, blockNumber, ...props }: UseQuoteTokenPriceProps) {
  const { provider } = useProvider()
  const quoteToken = useQuoteToken(address)

  return useQuery({
    queryKey: ['pairPrice', quoteToken?.usdcPair?.address, quoteToken?.usdcPair?.reversed],
    queryFn: async () => {
      if (!quoteToken) return
      if (!quoteToken.usdcPair) return new Fraction(1, 1)

      return await getPairPrice(provider, quoteToken.usdcPair, blockNumber)
    },
    enabled: Boolean(quoteToken),
    ...props,
  })
}
