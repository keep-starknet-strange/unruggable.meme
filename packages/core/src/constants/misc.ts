import { Percent } from '@uniswap/sdk-core'

import { getStartingTick } from '../utils/ekubo'

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
  LAUNCH_ON_EKUBO = 'launch_on_ekubo',
  LAUNCH_ON_STARKDEFI = 'launch_on_starkdefi',
  APPROVE = 'approve',
  GET_REMAINING_TIME = 'get_remaining_time',
  LAUNCHED_WITH_LIQUIDITY_PARAMETERS = 'launched_with_liquidity_parameters',
  GET_LOCK_DETAILS = 'get_lock_details',
  LAUNCHED_AT_BLOCK_NUMBER = 'launched_at_block_number',
  GET_RESERVES = 'get_reserves',
  LIQUIDITY_POSITION_DETAILS = 'liquidity_position_details',
  WITHDRAW_FEES = 'withdraw_fees',
  EXTEND_LOCK = 'extend_lock',
  BALANCE_OF_CAMEL = 'balanceOf',
  BALANCE_OF = 'balance_of',
  TRANSFER = 'transfer',
  GET_TOKEN_INFOS = 'get_token_info',
}

export enum LiquidityType {
  JEDISWAP_ERC20 = 'JEDISWAP_ERC20',
  STARKDEFI_ERC20 = 'STARKDEFI_ERC20',
  EKUBO_NFT = 'EKUBO_NFT',
}

export const STARKNET_POLLING = 3_000 // 3s
export const STARKNET_MAX_BLOCK_TIME = 3600 * 2 // 2h

export const PERCENTAGE_INPUT_PRECISION = 2

export const MIN_STARTING_MCAP = 5_000 // $5k
export const RECOMMENDED_STARTING_MCAP = 10_000 // $12k

export const MIN_HODL_LIMIT = new Percent(1, 200) // 0.5%
export const MAX_HODL_LIMIT = new Percent(1, 1) // 100%
export const RECOMMENDED_HODL_LIMIT = new Percent(1, 100) // 1%

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

export const MIN_EKUBO_FEES = new Percent(0, 1) // 0%
export const MAX_EKUBO_FEES = new Percent(2, 100) // 2%
export const RECOMMENDED_EKUBO_FEES = new Percent(3, 1000) // 0.3%

// Ekubo

export const EKUBO_TICK_SIZE = 1.000001
const EKUBO_MAX_PRICE = '0x100000000000000000000000000000000' // 2 ** 128

export const EKUBO_TICK_SPACING = 5982 // log(1 + 0.6%) / log(1.000001) => 0.6% is the tick spacing percentage
export const EKUBO_TICK_SIZE_LOG = Math.log(EKUBO_TICK_SIZE)
export const EKUBO_FEES_MULTIPLICATOR = EKUBO_MAX_PRICE
export const EKUBO_BOUND = getStartingTick(+EKUBO_MAX_PRICE)
