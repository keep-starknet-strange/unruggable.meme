import { LiquidityType } from 'src/constants/misc'
import i129 from 'src/utils/i129'
import { StateCreator } from 'zustand'

import { StoreState } from '../index'

export type MemecoinSlice = State & Actions

// Memecoin

interface EkuboPoolKey {
  token0: string
  token1: string
  fee: string
  tickSpacing: string
  extension: string
}

interface EkuboBounds {
  lower: i129
  upper: i129
}

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

interface BaseLiquidity {
  type: LiquidityType
  lockManager: string
  unlockTime: number
  owner: string
  quoteToken: string
}

export interface JediswapMemecoin extends BaseLaunchedMemecoin {
  liquidity: {
    type: LiquidityType.JEDISWAP_ERC20 | LiquidityType.STARKDEFI_ERC20
    lockPosition: string
    quoteAmount: string
  } & Omit<BaseLiquidity, 'type'>
}

export interface EkuboMemecoin extends BaseLaunchedMemecoin {
  liquidity: {
    type: LiquidityType.EKUBO_NFT
    ekuboId: string
    startingTick: number
    poolKey: EkuboPoolKey
    bounds: EkuboBounds
  } & Omit<BaseLiquidity, 'type'>
}

type LaunchedMemecoin = JediswapMemecoin | EkuboMemecoin

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
