// import { Percent } from '@uniswap/sdk-core'

export const MAX_HOLDERS_PER_DEPLOYMENT = 10
export const DECIMALS = 18

export enum Selector {
  CREATE_MEMECOIN = 'create_memecoin',
  IS_MEMECOIN = 'is_memecoin',
  AGGREGATE = 'aggregate',
  NAME = 'name',
  SYMBOL = 'symbol',
  IS_LAUNCHED = 'is_launched',
  GET_TEAM_ALLOCATION = 'get_team_allocation',
  TOTAL_SUPPLY = 'total_supply',
  OWNER = 'owner',
  LOCKED_LIQUIDITY = 'locked_liquidity',
}

export enum LiquidityType {
  EKUBO = 'Ekubo',
  JEDISWAP = 'Jediswap',
}

export const MIN_STARTING_MCAP = 10_000 // $10k

export const TRANSFER_RESTRICTION_DELAY_STEP = 15 // 15m
export const MIN_TRANSFER_RESTRICTION_DELAY = 30 // 30m
export const MAX_TRANSFER_RESTRICTION_DELAY = 1440 // 24h

// export const MIN_HODL_LIMIT = new Percent(1, 200) // 0.5%
