import { LiquidityType } from '../constants/misc'

interface i129 {
  mag: string
  sign: string
}

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

interface BaseLiquidity {
  type: LiquidityType
  lockManager: string
  unlockTime: number
  owner: string
  quoteToken: string
}

export type JediswapLiquidity = {
  type: LiquidityType.JEDISWAP_ERC20 | LiquidityType.STARKDEFI_ERC20
  lockPosition: string
  quoteAmount: bigint
} & Omit<BaseLiquidity, 'type'>

export type EkuboLiquidity = {
  type: LiquidityType.EKUBO_NFT
  ekuboId: string
  startingTick: number
  poolKey: EkuboPoolKey
  bounds: EkuboBounds
} & Omit<BaseLiquidity, 'type'>

export type LaunchedLiquidity = JediswapLiquidity | EkuboLiquidity

export type MemecoinLaunchData =
  | {
      isLaunched: false
    }
  | {
      isLaunched: true
      teamAllocation: bigint
      blockNumber: number
      liquidity: LaunchedLiquidity
    }
