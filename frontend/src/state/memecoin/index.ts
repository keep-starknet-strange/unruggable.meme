import { LiquidityType } from 'src/constants/misc'
import { StateCreator } from 'zustand'

import { StoreState } from '../index'

export type MemecoinSlice = State & Actions

// Memecoin

interface BaseMemecoin {
  address: string
  name: string
  symbol: string
  totalSupply: string
  isLaunched: boolean
  owner: string
}

interface BaseLaunchedMemecoin extends BaseMemecoin {
  isLaunched: true
  launch: {
    blockNumber: number
    teamAllocation: string
  }
}

interface JediswapMemecoin extends BaseLaunchedMemecoin {
  liquidity: {
    type: LiquidityType.ERC20
    lockManager: string
    lockPosition: string
    unlockTime: number
    owner: string
    quoteToken: string
    quoteAmount: string
  }
}

interface EkuboMemecoin extends BaseLaunchedMemecoin {
  liquidity: {
    type: LiquidityType.NFT
    lockManager: string
    ekuboId: string
    startingTick: number
    unlockTime: number
    owner: string
    quoteToken: string
  }
}

export type LaunchedMemecoin = JediswapMemecoin | EkuboMemecoin

interface NotLaunchedMemecoin extends BaseMemecoin {
  isLaunched: false
}

type Memecoin = LaunchedMemecoin | NotLaunchedMemecoin

// Liquidity

interface State {
  memecoin: Memecoin | null
  needsMemecoinRefresh: boolean
  tokenAddress: string | null
  ruggable: boolean | null
}

interface Actions {
  setTokenAddress: (tokenAddress: string) => void
  setMemecoin: (memecoin: Memecoin) => void
  resetMemecoin: () => void
  refreshMemecoin: () => void
  setRuggable: () => void
  startRefresh: () => void
}

const initialState = {
  memecoin: null,
  liquidityPosition: null,
  needsMemecoinRefresh: false,
  tokenAddress: null,
  ruggable: null,
}

export const createMemecoinSlice: StateCreator<StoreState, [['zustand/immer', never]], [], MemecoinSlice> = (set) => ({
  ...initialState,

  setRuggable: () => set({ ruggable: true }),
  setTokenAddress: (tokenAddress) => set({ ...initialState, needsMemecoinRefresh: true, tokenAddress }), // also reset the state
  setMemecoin: (memecoin) => set({ memecoin, ruggable: false }),
  resetMemecoin: () => set({ ...initialState }),
  refreshMemecoin: () => set({ needsMemecoinRefresh: true }),
  startRefresh: () => set({ needsMemecoinRefresh: false }),
})
