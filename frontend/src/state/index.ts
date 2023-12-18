import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { immer } from 'zustand/middleware/immer'

import { ApplicationSlice, createApplicationSlice } from './application'
import { ContractsSlice, createContractsSlice } from './contracts'

export type StoreState = ApplicationSlice & ContractsSlice

const PERSISTING_KEYS: (keyof StoreState)[] = ['deployedContracts']

export const useBoundStore = create<StoreState>()(
  persist(
    immer<StoreState>((...a) => ({
      ...createApplicationSlice(...a),
      ...createContractsSlice(...a),
    })),
    {
      name: 'unruggable-state-storage',
      partialize: (state: StoreState) =>
        PERSISTING_KEYS.reduce<StoreState>((acc, key) => {
          ;(acc as any)[key] = state[key]
          return acc
        }, {} as StoreState),
    }
  )
)
