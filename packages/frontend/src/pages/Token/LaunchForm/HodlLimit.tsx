import { zodResolver } from '@hookform/resolvers/zod'
import moment from 'moment'
import { useCallback, useMemo } from 'react'
import { useForm } from 'react-hook-form'
import Input from 'src/components/Input'
import PercentInput from 'src/components/Input/PercentInput'
import Slider from 'src/components/Slider'
import {
  MAX_HODL_LIMIT,
  MAX_TRANSFER_RESTRICTION_DELAY,
  MIN_HODL_LIMIT,
  MIN_TRANSFER_RESTRICTION_DELAY,
  PERCENTAGE_INPUT_PRECISION,
  RECOMMENDED_HODL_LIMIT,
  TRANSFER_RESTRICTION_DELAY_STEP,
} from 'src/constants/misc'
import { useHodlLimitForm } from 'src/hooks/useLaunchForm'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseMinutesDuration } from 'src/utils/moment'
import { percentInput } from 'src/utils/zod'
import { z } from 'zod'

import { FormPageProps, Submit } from './common'
import * as styles from './style.css'

// zod schemes

const schema = z.object({
  hodlLimit: percentInput
    .refine(
      (input) => +input <= +MAX_HODL_LIMIT.toFixed(PERCENTAGE_INPUT_PRECISION),
      `Hodl limit cannot exceed ${+MAX_HODL_LIMIT.toFixed(PERCENTAGE_INPUT_PRECISION)}%`,
    )
    .refine(
      (input) => +input >= +MIN_HODL_LIMIT.toFixed(PERCENTAGE_INPUT_PRECISION),
      `Hodl limit cannot fall behind ${+MIN_HODL_LIMIT.toFixed(PERCENTAGE_INPUT_PRECISION)}%`,
    ),
})

export default function HodlLimitForm({ next, previous }: FormPageProps) {
  const { hodlLimit, antiBotPeriod, setHodlLimit, setAntiBotPeriod } = useHodlLimitForm()

  // form
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: {
      hodlLimit: hodlLimit ?? undefined,
    },
  })

  const parsedAntiBotPeriod = useMemo(
    () => parseMinutesDuration(moment.duration(antiBotPeriod, 'minutes')),
    [antiBotPeriod],
  )

  const submit = useCallback(
    (data: z.infer<typeof schema>) => {
      setHodlLimit(data.hodlLimit)
      next()
    },
    [next, setHodlLimit],
  )

  return (
    <Column as="form" onSubmit={handleSubmit(submit)} gap="42">
      <Text.Custom color="text2" fontWeight="normal" fontSize="24">
        Anti bot
      </Text.Custom>

      <Column gap="16">
        <Column gap="8">
          <Text.HeadlineSmall>Hold limit</Text.HeadlineSmall>
          <PercentInput
            addon={<Text.HeadlineSmall>%</Text.HeadlineSmall>}
            placeholder={`${RECOMMENDED_HODL_LIMIT.toFixed(PERCENTAGE_INPUT_PRECISION)} (recommended)`}
            {...register('hodlLimit')}
          />

          <Box className={styles.errorContainer}>
            {errors.hodlLimit?.message ? <Text.Error>{errors.hodlLimit.message}</Text.Error> : null}
          </Box>
        </Column>

        <Column gap="8">
          <Text.HeadlineSmall>Disable anti bot after</Text.HeadlineSmall>
          <Slider
            value={antiBotPeriod}
            min={MIN_TRANSFER_RESTRICTION_DELAY}
            step={TRANSFER_RESTRICTION_DELAY_STEP}
            max={MAX_TRANSFER_RESTRICTION_DELAY}
            onSlidingChange={setAntiBotPeriod}
            addon={<Input value={parsedAntiBotPeriod} />}
          />
        </Column>
      </Column>

      <Submit previous={previous} />
    </Column>
  )
}
