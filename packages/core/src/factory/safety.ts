import { Fraction, Percent } from '@uniswap/sdk-core'
import moment from 'moment'

import { QUOTE_TOKENS } from '../constants'
import {
  LIQUIDITY_LOCK_SAFETY_BOUNDS,
  Safety as SafetyEnum,
  STARTING_MCAP_SAFETY_BOUNDS,
  TEAM_ALLOCATION_SAFETY_BOUNDS,
} from '../constants/safety'
import { Memecoin } from './memecoin'

export class Safety {
  public memecoin: Memecoin

  constructor(memecoin: Memecoin) {
    this.memecoin = memecoin
  }

  public async isSafe() {
    const totalSupply = await this.memecoin.getTotalSupply()
    const launch = await this.memecoin.getLaunch()

    if (!launch.isLaunched) return SafetyEnum.UNKNOWN

    const teamAllocationPercentage = new Percent(launch.teamAllocation.toString(), totalSupply.toString())
    const quoteToken = QUOTE_TOKENS[this.memecoin.config.chainId][launch.liquidity.quoteToken]
    const liquidityLock = moment.duration(moment.unix(launch.liquidity.unlockTime).diff(moment.now()), 'milliseconds')

    const safeties = {
      teamAllocation: Safety.getTeamAllocationSafety(teamAllocationPercentage),
      liquidityLock: Safety.getLiquidityLockSafety(liquidityLock),
      quoteToken: Safety.getQuoteTokenSafety(!quoteToken),
      // TODO: startingMcap
    }

    const lowestSafety = Object.values(safeties).reduce((acc, safety) => {
      if (safety > acc) return safety
      return acc
    }, SafetyEnum.SAFE)

    return {
      safety: lowestSafety,
      safeties,
    }
  }

  public static getTeamAllocationSafety(teamAllocationPercentage: Percent): SafetyEnum {
    if (teamAllocationPercentage.greaterThan(TEAM_ALLOCATION_SAFETY_BOUNDS[SafetyEnum.CORRECT])) {
      return SafetyEnum.DANGEROUS
    }

    if (teamAllocationPercentage.greaterThan(TEAM_ALLOCATION_SAFETY_BOUNDS[SafetyEnum.SAFE])) {
      return SafetyEnum.CORRECT
    }

    return SafetyEnum.SAFE
  }

  public static getLiquidityLockSafety(liquidityLock: moment.Duration): SafetyEnum {
    if (liquidityLock.asMonths() >= LIQUIDITY_LOCK_SAFETY_BOUNDS[SafetyEnum.SAFE].asMonths()) return SafetyEnum.SAFE
    if (liquidityLock.asMonths() >= LIQUIDITY_LOCK_SAFETY_BOUNDS[SafetyEnum.CORRECT].asMonths())
      return SafetyEnum.CORRECT

    return SafetyEnum.DANGEROUS
  }

  public static getQuoteTokenSafety(isUnknown: boolean) {
    return isUnknown ? SafetyEnum.DANGEROUS : SafetyEnum.SAFE
  }

  public static getStartingMarketCapSafety(teamAllocation: Percent, startingMcap?: Fraction) {
    if (!startingMcap) return SafetyEnum.DANGEROUS

    if (
      startingMcap?.lessThan(STARTING_MCAP_SAFETY_BOUNDS[SafetyEnum.CORRECT].mcap) ||
      startingMcap.multiply(teamAllocation).greaterThan(STARTING_MCAP_SAFETY_BOUNDS[SafetyEnum.CORRECT].teamAllocatoion)
    ) {
      return SafetyEnum.DANGEROUS
    }

    if (
      startingMcap?.lessThan(STARTING_MCAP_SAFETY_BOUNDS[SafetyEnum.SAFE].mcap) ||
      startingMcap.multiply(teamAllocation).greaterThan(STARTING_MCAP_SAFETY_BOUNDS[SafetyEnum.SAFE].teamAllocatoion)
    ) {
      return SafetyEnum.CORRECT
    }

    return SafetyEnum.SAFE
  }
}
