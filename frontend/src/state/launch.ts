import { MAX_LIQUIDITY_LOCK_PERIOD, MAX_TRANSFER_RESTRICTION_DELAY } from 'src/constants/misc'
import { StateCreator } from 'zustand'

import { StoreState } from './index'

export type LaunchSlice = State & Actions

interface State {
  hodlLimit: string | null
  antiBotPeriod: number
  liquidityLockPeriod: number
  startingMcap: string | null
  launch: (() => void) | null
}

interface Actions {
  setHodlLimit: (hodlLimit: string) => void
  setAntiBotPeriod: (antiBotPeriod: number) => void
  setLiquidityLockPeriod: (liquidityLockPeriod: number) => void
  setStartingMcap: (startingMcap: string | null) => void
  setLaunch: (launch: () => void) => void
}

export const createLaunchSlice: StateCreator<StoreState, [['zustand/immer', never]], [], LaunchSlice> = (set) => ({
  hodlLimit: null,
  antiBotPeriod: MAX_TRANSFER_RESTRICTION_DELAY,
  liquidityLockPeriod: MAX_LIQUIDITY_LOCK_PERIOD,
  startingMcap: null,
  launch: null,

  setHodlLimit: (hodlLimit) => set({ hodlLimit }),
  setAntiBotPeriod: (antiBotPeriod) => set({ antiBotPeriod }),
  setLiquidityLockPeriod: (liquidityLockPeriod) => set({ liquidityLockPeriod }),
  setStartingMcap: (startingMcap) => set({ startingMcap }),
  setLaunch: (launch: () => void) => set({ launch }),
})
