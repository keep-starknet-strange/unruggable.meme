import { Percent } from '@uniswap/sdk-core'
import { Safety, TEAM_ALLOCATION_SAFETY_BOUNDS } from 'src/constants/safety'

export function getTeamAllocationSafety(teamAllocationPercentage: Percent) {
  if (teamAllocationPercentage.greaterThan(TEAM_ALLOCATION_SAFETY_BOUNDS[Safety.CORRECT])) return Safety.DANGEROUS
  if (teamAllocationPercentage.greaterThan(TEAM_ALLOCATION_SAFETY_BOUNDS[Safety.SAFE])) return Safety.CORRECT
  return Safety.SAFE
}
