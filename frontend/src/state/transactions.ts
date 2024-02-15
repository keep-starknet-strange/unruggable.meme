import { Call } from 'starknet'
import { StateCreator } from 'zustand'

import { StoreState } from './index'

export type TransactionsSlice = State & Actions

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

export const createTransactionsSlice: StateCreator<StoreState, [['zustand/immer', never]], [], TransactionsSlice> = (
  set
) => ({
  invokeTransactionDetails: null,

  prepareTransaction: (invokeTransactionDetails) => set({ invokeTransactionDetails }),
  resetTransaction: () => set({ invokeTransactionDetails: null }),
})
