import { StateCreator } from 'zustand'

import { StoreState } from './index'

export type ContractsSlice = State & Actions

interface State {
  deployedContracts: string[]
}

interface Actions {
  pushDeployedContract: (...contracts: string[]) => void
}

const initialState: State = {
  deployedContracts: [],
}

// Create a deployment slice with Zustand and persist middleware
export const createContractsSlice: StateCreator<StoreState, [['zustand/immer', never]], [], ContractsSlice> = (
  set
) => ({
  ...initialState,

  pushDeployedContract: (...contracts: string[]) =>
    set((state) => {
      state.deployedContracts.push(...(contracts as any[]))
    }),
})
