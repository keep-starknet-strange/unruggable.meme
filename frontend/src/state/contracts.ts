import { StateCreator } from 'zustand'

import { StoreState } from './index'

export type ContractsSlice = State & Actions

export interface TokenContract {
  address: string
  name: string
  symbol: string
  maxSupply: string
  teamAllocation: string
  launched: boolean
}

interface State {
  deployedTokenContracts: TokenContract[]
}

interface Actions {
  pushDeployedTokenContracts: (...contracts: TokenContract[]) => void
}

const initialState: State = {
  deployedTokenContracts: [],
}

// Create a deployment slice with Zustand and persist middleware
export const createContractsSlice: StateCreator<StoreState, [['zustand/immer', never]], [], ContractsSlice> = (
  set
) => ({
  ...initialState,

  pushDeployedTokenContracts: (...contracts: TokenContract[]) =>
    set((state) => {
      state.deployedTokenContracts.push(...(contracts as any[]))
    }),
})
