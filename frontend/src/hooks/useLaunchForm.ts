import { useBoundStore } from 'src/state'

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
    liquidityLockPeriod: state.liquidityLockPeriod,
    startingMcap: state.startingMcap,
    setLiquidityLockPeriod: state.setLiquidityLockPeriod,
    setStartingMcap: state.setStartingMcap,
  }))
}
