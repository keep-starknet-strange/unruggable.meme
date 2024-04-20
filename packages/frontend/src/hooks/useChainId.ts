import { starknetChainId, useNetwork } from '@starknet-react/core'
import { useMemo } from 'react'

export default function useChainId() {
  const { chain } = useNetwork()
  return useMemo(() => (chain.id ? starknetChainId(chain.id) : undefined), [chain.id])
}
