import { useBoundStore } from 'src/state'

export function useDeploymentStore() {
  return useBoundStore((state) => ({
    deployedTokenContracts: state.deployedTokenContracts,
    pushDeployedTokenContracts: state.pushDeployedTokenContracts,
  }))
}
