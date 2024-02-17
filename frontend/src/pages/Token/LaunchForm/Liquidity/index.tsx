import { zodResolver } from '@hookform/resolvers/zod'
import { useCallback, useMemo } from 'react'
import { useForm } from 'react-hook-form'
import NumericalInput from 'src/components/Input/NumericalInput'
import { AMM, MIN_STARTING_MCAP, RECOMMENDED_STARTING_MCAP } from 'src/constants/misc'
import { useAmm, useLiquidityForm } from 'src/hooks/useLaunchForm'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseFormatedAmount } from 'src/utils/amount'
import { currencyInput } from 'src/utils/zod'
import { z } from 'zod'

import { FormPageProps, Submit } from '../common'
import JediswapLiquidityForm from './Jediswap'
import * as styles from './style.css'

// zod schemes

const schema = z.object({
  startingMcap: currencyInput.refine((input) => +parseFormatedAmount(input) >= MIN_STARTING_MCAP, {
    message: `Market cap cannot fall behind $${MIN_STARTING_MCAP.toLocaleString()}`,
  }),
})

// eslint-disable-next-line import/no-unused-modules
export default function PriceForm({ next, previous }: FormPageProps) {
  const { startingMcap, setStartingMcap } = useLiquidityForm()
  const [amm] = useAmm()

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

  const submit = useCallback(
    (data: z.infer<typeof schema>) => {
      setStartingMcap(data.startingMcap)
      next()
    },
    [next, setStartingMcap]
  )

  const ammSpecificComponent = useMemo(() => {
    switch (amm) {
      case AMM.EKUBO:
        return null

      case AMM.JEDISWAP:
        return <JediswapLiquidityForm />
    }
  }, [amm])

  return (
    <Column gap="42">
      <Text.Custom color="text2" fontWeight="normal" fontSize="24">
        Liquidity
      </Text.Custom>

      <Column as="form" onSubmit={handleSubmit(submit)} gap="42">
        <Column gap="16">
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

          {ammSpecificComponent}
        </Column>

        <Submit previous={previous} />
      </Column>
    </Column>
  )
}
