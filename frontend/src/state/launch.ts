import { MAX_LIQUIDITY_LOCK_PERIOD, MAX_TRANSFER_RESTRICTION_DELAY } from 'src/constants/misc'
import { StateCreator } from 'zustand'

import { StoreState } from './index'

export type LaunchSlice = State & Actions

export interface Holder {
  address: string
  amount: string
}

type TeamAllocation = Record<number, Holder>

interface State {
  hodlLimit: string | null
  antiBotPeriod: number
  liquidityLockPeriod: number
  startingMcap: string | null
  launch: (() => void) | null
  teamAllocation: TeamAllocation
}

interface Actions {
  setHodlLimit: (hodlLimit: string) => void
  setAntiBotPeriod: (antiBotPeriod: number) => void
  setLiquidityLockPeriod: (liquidityLockPeriod: number) => void
  setStartingMcap: (startingMcap: string | null) => void
  setLaunch: (launch: () => void) => void
  setTeamAllocationHolder: (holder: Holder, index: number) => void
  removeTeamAllocationHolder: (index: number) => void
}

export const createLaunchSlice: StateCreator<StoreState, [['zustand/immer', never]], [], LaunchSlice> = (set) => ({
  hodlLimit: null,
  antiBotPeriod: MAX_TRANSFER_RESTRICTION_DELAY,
  liquidityLockPeriod: MAX_LIQUIDITY_LOCK_PERIOD,
  startingMcap: null,
  launch: null,
  teamAllocation: {},

  setHodlLimit: (hodlLimit) => set({ hodlLimit }),
  setAntiBotPeriod: (antiBotPeriod) => set({ antiBotPeriod }),
  setLiquidityLockPeriod: (liquidityLockPeriod) => set({ liquidityLockPeriod }),
  setStartingMcap: (startingMcap) => set({ startingMcap }),
  setLaunch: (launch: () => void) => set({ launch }),
  setTeamAllocationHolder: (holder: Holder, index: number) =>
    set((state) => {
      state.teamAllocation[index] = holder
    }),
  removeTeamAllocationHolder: (index: number) =>
    set((state) => {
      delete state.teamAllocation[index]
      return state
    }),
})
