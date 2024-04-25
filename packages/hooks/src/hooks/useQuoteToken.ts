import { starknetChainId, useNetwork } from '@starknet-react/core'
import { QUOTE_TOKENS } from 'core/constants'
import { getChecksumAddress } from 'starknet'

export function useQuoteToken(address?: string) {
  const { chain } = useNetwork()

  if (!address) return

  const chainId = chain.id ? starknetChainId(chain.id) : undefined
  if (!chainId) return

  return QUOTE_TOKENS[chainId][getChecksumAddress(address)]
}
