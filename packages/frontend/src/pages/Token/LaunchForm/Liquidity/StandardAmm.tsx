import { zodResolver } from '@hookform/resolvers/zod'
import { LIQUIDITY_LOCK_PERIOD_STEP, MAX_LIQUIDITY_LOCK_PERIOD, MIN_LIQUIDITY_LOCK_PERIOD } from 'core/constants'
import moment from 'moment'
import { useCallback, useMemo } from 'react'
import { useForm } from 'react-hook-form'
import Input from 'src/components/Input'
import Slider from 'src/components/Slider'
import { FOREVER } from 'src/constants/misc'
import { useStandardAmmLiquidityForm } from 'src/hooks/useLaunchForm'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseMonthsDuration } from 'src/utils/moment'
import { z } from 'zod'

import { FormPageProps, Submit } from '../common'
import LiquidityTemplate, { liquiditySchema, useLiquidityTemplateForm } from './template'

export default function StandardAmmLiquidityForm({ next, previous }: FormPageProps) {
  const { liquidityLockPeriod, setLiquidityLockPeriod } = useStandardAmmLiquidityForm()

  // form
  const liquidityTemplateForm = useLiquidityTemplateForm<z.infer<typeof liquiditySchema>>()

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<z.infer<typeof liquiditySchema>>({
    resolver: zodResolver(liquiditySchema),
    defaultValues: liquidityTemplateForm.defaultValues,
  })

  const parsedLiquidityLockPeriod = useMemo(
    () =>
      liquidityLockPeriod === MAX_LIQUIDITY_LOCK_PERIOD
        ? FOREVER
        : parseMonthsDuration(moment.duration(liquidityLockPeriod, 'months')),
    [liquidityLockPeriod],
  )

  // submit
  const submit = useCallback(
    (data: z.infer<typeof liquiditySchema>) => {
      liquidityTemplateForm.submit(data)
      next()
    },
    [next, liquidityTemplateForm],
  )

  return (
    <Column as="form" onSubmit={handleSubmit(submit)} gap="42">
      <Column gap="16">
        <LiquidityTemplate register={register} errors={errors} />

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
      </Column>

      <Submit previous={previous} />
    </Column>
  )
}
