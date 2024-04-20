import { Fraction, Percent } from '@uniswap/sdk-core'
import { useMemo } from 'react'
import { DECIMALS } from 'src/constants/misc'
import { useBoundStore } from 'src/state'
import { parseFormatedAmount } from 'src/utils/amount'
import { decimalsScale } from 'src/utils/decimalScale'

export function useHodlLimitForm() {
  return useBoundStore((state) => ({
    hodlLimit: state.hodlLimit,
    antiBotPeriod: state.antiBotPeriod,
    setHodlLimit: state.setHodlLimit,
    setAntiBotPeriod: state.setAntiBotPeriod,
  }))
}

export function useLiquidityForm() {
  return useBoundStore((state) => ({
    startingMcap: state.startingMcap,
    quoteTokenAddress: state.quoteTokenAddress,
    setStartingMcap: state.setStartingMcap,
    setQuoteTokenAddress: state.setQuoteTokenAddress,
  }))
}

export function useStandardAmmLiquidityForm() {
  return useBoundStore((state) => ({
    liquidityLockPeriod: state.liquidityLockPeriod,
    setLiquidityLockPeriod: state.setLiquidityLockPeriod,
  }))
}

export function useEkuboLiquidityForm() {
  return useBoundStore((state) => ({
    ekuboFees: state.ekuboFees,
    setEkuboFees: state.setEkuboFees,
  }))
}

export function useAmm() {
  return useBoundStore((state) => [state.amm, state.setAMM] as const)
}

export function useResetLaunchForm() {
  return useBoundStore((state) => state.resetLaunchForm)
}

export function useTeamAllocation() {
  return useBoundStore((state) => ({
    teamAllocation: state.teamAllocation,
    setTeamAllocationHolder: state.setTeamAllocationHolder,
    removeTeamAllocationHolder: state.removeTeamAllocationHolder,
  }))
}

export function useTeamAllocationTotalPercentage(totalSupply?: string) {
  const { teamAllocation } = useTeamAllocation()

  return useMemo(() => {
    if (!totalSupply) return

    const totalTeamAllocation = Object.values(teamAllocation).reduce(
      (acc, holder) => acc.add(parseFormatedAmount(holder?.amount ?? 0)),
      new Fraction(0)
    )

    return new Percent(totalTeamAllocation.quotient, new Fraction(totalSupply, decimalsScale(DECIMALS)).quotient)
  }, [totalSupply, teamAllocation])
}
