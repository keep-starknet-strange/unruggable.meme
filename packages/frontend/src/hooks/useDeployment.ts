import { useCallback } from 'react'
import { useBoundStore } from 'src/state'
import { getChecksumAddress } from 'starknet'

import useChainId from './useChainId'

export function useDeploymentStore() {
  const { deployedTokenContracts, pushDeployedTokenContract } = useBoundStore((state) => ({
    deployedTokenContracts: state.deployedTokenContracts,
    pushDeployedTokenContract: state.pushDeployedTokenContract,
  }))

  // starknet
  const chainId = useChainId()

  const safelyPushDeployedTokenContracts = useCallback(
    (newTokenContract: Parameters<typeof pushDeployedTokenContract>[0]) => {
      if (!chainId) return

      for (const tokenContract of deployedTokenContracts[chainId] ?? []) {
        if (getChecksumAddress(tokenContract.address) === getChecksumAddress(newTokenContract.address)) {
          return
        }
      }

      pushDeployedTokenContract(newTokenContract, chainId)
    },
    [chainId, deployedTokenContracts, pushDeployedTokenContract],
  )

  return [chainId ? deployedTokenContracts[chainId] ?? [] : [], safelyPushDeployedTokenContracts] as const
}
