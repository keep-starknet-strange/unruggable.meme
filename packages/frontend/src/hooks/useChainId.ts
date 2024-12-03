import { starknetChainId, useNetwork } from '@starknet-react/core'
import { useMemo } from 'react'
import { constants } from 'starknet'

export default function useChainId(): constants.StarknetChainId | undefined {
  const { chain } = useNetwork()
  return useMemo(() => (chain.id ? starknetChainId(chain.id) : undefined), [chain.id])
}
