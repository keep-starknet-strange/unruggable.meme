import { useCallback } from 'react'
import { useBoundStore } from 'src/state'
import { getChecksumAddress } from 'starknet'

export function useDeploymentStore() {
  const { deployedTokenContracts, pushDeployedTokenContracts } = useBoundStore((state) => ({
    deployedTokenContracts: state.deployedTokenContracts,
    pushDeployedTokenContracts: state.pushDeployedTokenContracts,
  }))

  const safelyPushDeployedTokenContracts = useCallback(
    (newTokenContract: Parameters<typeof pushDeployedTokenContracts>[0]) => {
      for (const tokenContract of deployedTokenContracts) {
        if (getChecksumAddress(tokenContract.address) === getChecksumAddress(newTokenContract.address)) {
          return
        }
      }

      pushDeployedTokenContracts(newTokenContract)
    },
    [deployedTokenContracts, pushDeployedTokenContracts]
  )

  return [deployedTokenContracts, safelyPushDeployedTokenContracts] as const
}
