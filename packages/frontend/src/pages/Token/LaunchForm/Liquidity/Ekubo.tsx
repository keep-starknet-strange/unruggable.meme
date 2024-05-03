import { zodResolver } from '@hookform/resolvers/zod'
import { MAX_EKUBO_FEES, MIN_EKUBO_FEES, RECOMMENDED_EKUBO_FEES } from 'core/constants'
import { useCallback } from 'react'
import { useForm } from 'react-hook-form'
import PercentInput from 'src/components/Input/PercentInput'
import { PERCENTAGE_INPUT_PRECISION } from 'src/constants/misc'
import { useEkuboLiquidityForm } from 'src/hooks/useLaunchForm'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { percentInput } from 'src/utils/zod'
import { z } from 'zod'

import { FormPageProps, Submit } from '../common'
import * as styles from './style.css'
import LiquidityTemplate, { liquiditySchema, useLiquidityTemplateForm } from './template'

// zod schemes

const schema = z.object({
  ekuboFees: percentInput
    .refine(
      (input) => +input <= +MAX_EKUBO_FEES.toFixed(PERCENTAGE_INPUT_PRECISION),
      `Hodl limit cannot exceed ${+MAX_EKUBO_FEES.toFixed(PERCENTAGE_INPUT_PRECISION)}%`,
    )
    .refine(
      (input) => +input >= +MIN_EKUBO_FEES.toFixed(PERCENTAGE_INPUT_PRECISION),
      `Hodl limit cannot fall behind ${+MIN_EKUBO_FEES.toFixed(PERCENTAGE_INPUT_PRECISION)}%`,
    ),
})

export default function EkuboLiquidityForm({ previous, next }: FormPageProps) {
  const { ekuboFees, setEkuboFees } = useEkuboLiquidityForm()

  // form
  const liquidityTemplateForm = useLiquidityTemplateForm<z.infer<typeof liquiditySchema>>()

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<z.infer<typeof liquiditySchema> & z.infer<typeof schema>>({
    resolver: zodResolver(liquiditySchema.merge(schema)),
    defaultValues: {
      ...liquidityTemplateForm.defaultValues,
      ekuboFees: ekuboFees ?? undefined,
    },
  })

  // submit
  const submit = useCallback(
    (data: z.infer<typeof liquiditySchema> & z.infer<typeof schema>) => {
      liquidityTemplateForm.submit(data)
      setEkuboFees(data.ekuboFees)
      next()
    },
    [liquidityTemplateForm, setEkuboFees, next],
  )

  return (
    <Column as="form" onSubmit={handleSubmit(submit)} gap="42">
      <Column gap="16">
        <LiquidityTemplate register={register} errors={errors} />

        <Column gap="8">
          <Text.HeadlineSmall>Ekubo fees</Text.HeadlineSmall>

          <PercentInput
            addon={<Text.HeadlineSmall>%</Text.HeadlineSmall>}
            placeholder={`${RECOMMENDED_EKUBO_FEES.toFixed(PERCENTAGE_INPUT_PRECISION)} (recommended)`}
            {...register('ekuboFees')}
          />

          <Box className={styles.errorContainer}>
            {errors.ekuboFees?.message ? <Text.Error>{errors.ekuboFees.message}</Text.Error> : null}
          </Box>
        </Column>
      </Column>

      <Submit previous={previous} />
    </Column>
  )
}
