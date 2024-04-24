import { Fraction, Percent } from '@uniswap/sdk-core'
import {
  LIQUIDITY_LOCK_SAFETY_BOUNDS,
  Safety,
  STARTING_MCAP_SAFETY_BOUNDS,
  TEAM_ALLOCATION_SAFETY_BOUNDS,
} from 'core/constants'
import moment from 'moment'

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

export function getStartingMcapSafety(teamAllocation: Percent, startingMcap?: Fraction) {
  if (!startingMcap) return Safety.DANGEROUS

  if (
    startingMcap?.lessThan(STARTING_MCAP_SAFETY_BOUNDS[Safety.CORRECT].mcap) ||
    startingMcap.multiply(teamAllocation).greaterThan(STARTING_MCAP_SAFETY_BOUNDS[Safety.CORRECT].teamAllocatoion)
  ) {
    return Safety.DANGEROUS
  }

  if (
    startingMcap?.lessThan(STARTING_MCAP_SAFETY_BOUNDS[Safety.SAFE].mcap) ||
    startingMcap.multiply(teamAllocation).greaterThan(STARTING_MCAP_SAFETY_BOUNDS[Safety.SAFE].teamAllocatoion)
  ) {
    return Safety.CORRECT
  }

  return Safety.SAFE
}
