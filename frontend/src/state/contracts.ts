import { constants } from 'starknet'
import { StateCreator } from 'zustand'

import { StoreState } from './index'

export type ContractsSlice = State & Actions

export interface TokenContract {
  address: string
  name: string
  symbol: string
  totalSupply: string
}

interface State {
  deployedTokenContracts: { [chainId in constants.StarknetChainId]?: TokenContract[] }
}

interface Actions {
  pushDeployedTokenContract: (contract: TokenContract, chainId: constants.StarknetChainId) => void
}

const initialState: State = {
  deployedTokenContracts: {},
}

// Create a deployment slice with Zustand and persist middleware
export const createContractsSlice: StateCreator<StoreState, [['zustand/immer', never]], [], ContractsSlice> = (
  set
) => ({
  ...initialState,

  pushDeployedTokenContract: (contract: TokenContract, chainId: constants.StarknetChainId) =>
    set((state) => {
      state.deployedTokenContracts[chainId] ??= []
      state.deployedTokenContracts[chainId]?.push(contract)
    }),
})
