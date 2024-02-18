import { Fraction } from '@uniswap/sdk-core'
import { useCallback } from 'react'
import { useEkuboLiquidityForm, useHodlLimitForm, useLiquidityForm } from 'src/hooks/useLaunchForm'

import { LastFormPageProps } from '../common'
import LaunchTemplate from './template'

export default function EkuboLaunch({ previous }: LastFormPageProps) {
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { startingMcap } = useLiquidityForm()
  const { ekuboFees } = useEkuboLiquidityForm()

  console.log(ekuboFees)

  // team allocation buyout
  const teamAllocationBuyoutAmount = new Fraction(0)

  // launch
  const launch = useCallback(() => {
    console.log('ekubo')
  }, [])

  return <LaunchTemplate teamAllocationPrice={teamAllocationBuyoutAmount} previous={previous} next={launch} />
}
