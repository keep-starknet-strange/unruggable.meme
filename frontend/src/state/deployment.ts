import { create } from 'zustand'
import { persist } from 'zustand/middleware'

// Define the structure for a deployed contract
interface DeployedContract {
  address: string
  tx: string
}

// Define the structure of the deployment slice
interface DeploymentState {
  deployedContracts: DeployedContract[]
  addDeployedContract: (contract: DeployedContract) => void
  resetDeployedContracts: () => void
}

// Create a deployment slice with Zustand and persist middleware
export const useDeploymentStore = create<DeploymentState>()(
  persist(
    (set) => ({
      deployedContracts: [],

      addDeployedContract: (contract) =>
        set((state) => ({ deployedContracts: [...state.deployedContracts, contract] })),

      resetDeployedContracts: () => set({ deployedContracts: [] }),
    }),
    {
      name: 'unruggable-deployment-storage',
    }
  )
)
