import { Fraction, Percent } from '@uniswap/sdk-core'
import moment from 'moment'
import { LIQUIDITY_LOCK_SAFETY_BOUNDS, Safety, TEAM_ALLOCATION_SAFETY_BOUNDS } from 'src/constants/safety'

export function getTeamAllocationSafety(teamAllocation: Percent) {
  if (teamAllocation.greaterThan(TEAM_ALLOCATION_SAFETY_BOUNDS[Safety.CORRECT])) return Safety.DANGEROUS
  if (teamAllocation.greaterThan(TEAM_ALLOCATION_SAFETY_BOUNDS[Safety.SAFE])) return Safety.CORRECT
  return Safety.SAFE
}

export function getLiquidityLockSafety(liquidityLock: moment.Duration) {
  if (liquidityLock.asMonths() >= LIQUIDITY_LOCK_SAFETY_BOUNDS[Safety.SAFE].asMonths()) return Safety.SAFE
  if (liquidityLock.asMonths() >= LIQUIDITY_LOCK_SAFETY_BOUNDS[Safety.CORRECT].asMonths()) return Safety.CORRECT
  return Safety.DANGEROUS
}

export function getQuoteTokenSafety(isUnknown: boolean) {
  return isUnknown ? Safety.DANGEROUS : Safety.SAFE
}

export function getStartingMcapSafety(startingMcap?: Fraction) {
  return startingMcap ? Safety.SAFE : Safety.DANGEROUS // TODO: check starting mcap value if not undefined
}
