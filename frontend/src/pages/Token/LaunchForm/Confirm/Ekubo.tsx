import { Fraction } from '@uniswap/sdk-core'
import { useCallback, useEffect } from 'react'
import { useHodlLimitForm, useLaunch, useLiquidityForm } from 'src/hooks/useLaunchForm'

import LaunchTemplate from './template'

export default function EkuboLaunch() {
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { liquidityLockPeriod, startingMcap } = useLiquidityForm()

  // team allocation buyout
  const teamAllocationBuyoutAmount = new Fraction(0)

  // launch
  const launch = useCallback(() => {
    console.log('ekubo')
  }, [])

  // set launch
  const { setLaunch } = useLaunch()
  useEffect(() => {
    setLaunch(launch)
  }, [launch, setLaunch])

  return <LaunchTemplate teamAllocationPrice={teamAllocationBuyoutAmount} />
}
