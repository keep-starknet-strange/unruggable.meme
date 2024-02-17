import moment from 'moment'
import { useMemo } from 'react'
import Input from 'src/components/Input'
import Slider from 'src/components/Slider'
import {
  FOREVER,
  LIQUIDITY_LOCK_PERIOD_STEP,
  MAX_LIQUIDITY_LOCK_PERIOD,
  MIN_LIQUIDITY_LOCK_PERIOD,
} from 'src/constants/misc'
import { useJediswapLiquidityForm } from 'src/hooks/useLaunchForm'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseMonthsDuration } from 'src/utils/moment'

export default function JediswapLiquidityForm() {
  const { liquidityLockPeriod, setLiquidityLockPeriod } = useJediswapLiquidityForm()

  const parsedLiquidityLockPeriod = useMemo(
    () =>
      liquidityLockPeriod === MAX_LIQUIDITY_LOCK_PERIOD
        ? FOREVER
        : parseMonthsDuration(moment.duration(liquidityLockPeriod, 'months')),
    [liquidityLockPeriod]
  )

  return (
    <Column gap="8">
      <Text.HeadlineSmall>Lock liquidity for</Text.HeadlineSmall>
      <Slider
        value={liquidityLockPeriod}
        min={MIN_LIQUIDITY_LOCK_PERIOD}
        step={LIQUIDITY_LOCK_PERIOD_STEP}
        max={MAX_LIQUIDITY_LOCK_PERIOD}
        onSlidingChange={setLiquidityLockPeriod}
        addon={<Input value={parsedLiquidityLockPeriod} />}
      />
    </Column>
  )
}
