import { Call } from 'starknet'
import { StateCreator } from 'zustand'

import { StoreState } from './index'

export type TransactionSlice = State & Actions

export interface InvokeTransactionDetails {
  calls: Call[]
  action: string
  onSuccess?: () => void
}

interface State {
  invokeTransactionDetails: InvokeTransactionDetails | null
}

interface Actions {
  prepareTransaction: (invokeTransactionDetails: InvokeTransactionDetails) => void
  resetTransaction: () => void
}

export const createTransactionSlice: StateCreator<StoreState, [['zustand/immer', never]], [], TransactionSlice> = (
  set
) => ({
  invokeTransactionDetails: null,

  prepareTransaction: (invokeTransactionDetails) => set({ invokeTransactionDetails }),
  resetTransaction: () => set({ invokeTransactionDetails: null }),
})
