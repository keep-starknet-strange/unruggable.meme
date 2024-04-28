export enum LiquidityType {
  JEDISWAP_ERC20 = 'JEDISWAP_ERC20',
  STARKDEFI_ERC20 = 'STARKDEFI_ERC20',
  EKUBO_NFT = 'EKUBO_NFT',
}

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

export type LaunchedMemecoin = JediswapMemecoin | EkuboMemecoin

interface NotLaunchedMemecoin extends BaseMemecoin {
  isLaunched: false
}

export type Memecoin = LaunchedMemecoin | NotLaunchedMemecoin
