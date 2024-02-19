import { useMemo } from 'react'
import { QUOTE_TOKENS } from 'src/constants/tokens'

import useChainId from './useChainId'

export default function useQuoteToken(address?: string) {
  // starknet
  const chainId = useChainId()

  return useMemo(() => (chainId && address ? QUOTE_TOKENS[chainId][address] : null), [chainId, address])
}
