import { Percent } from '@uniswap/sdk-core'

export const MAX_TEAM_ALLOCATION_HOLDERS_COUNT = 10
export const MAX_TEAM_ALLOCATION_TOTAL_SUPPLY_PERCENTAGE = new Percent(10, 100) // 10%
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
  LAUNCH_ON_JEDISWAP = 'launch_on_jediswap',
  APPROVE = 'approve',
  GET_REMAINING_TIME = 'get_remaining_time',
  LAUNCHED_WITH_LIQUIDITY_PARAMETERS = 'launched_with_liquidity_parameters',
  GET_LOCK_DETAILS = 'get_lock_details',
  LAUNCHED_AT_BLOCK_NUMBER = 'launched_at_block_number',
  GET_RESERVES = 'get_reserves',
  LIQUIDITY_POSITION_DETAILS = 'liquidity_position_details',
  WITHDRAW_FEES = 'withdraw_fees',
  EXTEND_LOCK = 'extend_lock',
}

export enum LiquidityType {
  ERC20 = 'JediERC20',
  NFT = 'EkuboNFT',
}

export const MIN_STARTING_MCAP = 5_000 // $5k
export const RECOMMENDED_STARTING_MCAP = 10_000 // $12k

export const TRANSFER_RESTRICTION_DELAY_STEP = 15 // 15m
export const MIN_TRANSFER_RESTRICTION_DELAY = 30 // 30m
export const MAX_TRANSFER_RESTRICTION_DELAY = 1440 // 24h

export const LIQUIDITY_LOCK_PERIOD_STEP = 1 // 1 month
export const MIN_LIQUIDITY_LOCK_PERIOD = 6 // 6 months
export const MAX_LIQUIDITY_LOCK_PERIOD = 25 // 2 years and 1 month

export const LIQUIDITY_LOCK_INCREASE_STEP = 1 // 1 month
export const MIN_LIQUIDITY_LOCK_INCREASE = 1 // 1 months
export const MAX_LIQUIDITY_LOCK_INCREASE = 25 // 2 years and 1 month

export const LIQUIDITY_LOCK_FOREVER_TIMESTAMP = 9999999999 // 20/11/2286
export const FOREVER = 'Forever'

// export const MIN_HODL_LIMIT = new Percent(1, 200) // 0.5%
