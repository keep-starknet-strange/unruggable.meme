import { zodResolver } from '@hookform/resolvers/zod'
import moment from 'moment'
import { useCallback, useMemo } from 'react'
import { useForm } from 'react-hook-form'
import Input from 'src/components/Input'
import NumericalInput from 'src/components/Input/NumericalInput'
import Slider from 'src/components/Slider'
import {
  FOREVER,
  LIQUIDITY_LOCK_PERIOD_STEP,
  MAX_LIQUIDITY_LOCK_PERIOD,
  MIN_LIQUIDITY_LOCK_PERIOD,
  MIN_STARTING_MCAP,
  RECOMMENDED_STARTING_MCAP,
} from 'src/constants/misc'
import { useLiquidityForm } from 'src/hooks/useLaunchForm'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseFormatedAmount } from 'src/utils/amount'
import { parseMonthsDuration } from 'src/utils/moment'
import { currencyInput } from 'src/utils/zod'
import { z } from 'zod'

import { FormPageProps, Submit } from './common'
import * as styles from './style.css'

// zod schemes

const schema = z.object({
  startingMcap: currencyInput.refine((input) => +parseFormatedAmount(input) >= MIN_STARTING_MCAP, {
    message: `Market cap cannot fall behind $${MIN_STARTING_MCAP.toLocaleString()}`,
  }),
})

export default function LiquidityForm({ next, previous }: FormPageProps) {
  const { liquidityLockPeriod, startingMcap, setLiquidityLockPeriod, setStartingMcap } = useLiquidityForm()

  // form
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: {
      startingMcap: startingMcap ?? undefined,
    },
  })

  const parsedLiquidityLockPeriod = useMemo(
    () =>
      liquidityLockPeriod === MAX_LIQUIDITY_LOCK_PERIOD
        ? FOREVER
        : parseMonthsDuration(moment.duration(liquidityLockPeriod, 'months')),
    [liquidityLockPeriod]
  )

  const submit = useCallback(
    (data: z.infer<typeof schema>) => {
      setStartingMcap(data.startingMcap)
      next()
    },
    [next, setStartingMcap]
  )

  return (
    <Column gap="42">
      <Text.Custom color="text2" fontWeight="normal" fontSize="24">
        Liquidity
      </Text.Custom>

      <Column as="form" onSubmit={handleSubmit(submit)} gap="42">
        <Column gap="16">
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

          <Column gap="8">
            <Text.HeadlineSmall>Starting market cap</Text.HeadlineSmall>

            <NumericalInput
              addon={<Text.HeadlineSmall>$</Text.HeadlineSmall>}
              placeholder={`${RECOMMENDED_STARTING_MCAP.toLocaleString()} (recommended)`}
              {...register('startingMcap')}
            />

            <Box className={styles.errorContainer}>
              {errors.startingMcap?.message ? <Text.Error>{errors.startingMcap.message}</Text.Error> : null}
            </Box>
          </Column>
        </Column>

        <Submit previous={previous} />
      </Column>
    </Column>
  )
}
