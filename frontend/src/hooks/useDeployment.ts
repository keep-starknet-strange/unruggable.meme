import { useBoundStore } from 'src/state'

export function useDeploymentStore() {
  return useBoundStore((state) => ({
    deployedContracts: state.deployedContracts,
    pushDeployedContract: state.pushDeployedContract,
  }))
}
