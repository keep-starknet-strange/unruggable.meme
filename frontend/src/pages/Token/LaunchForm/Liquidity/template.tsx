import clsx from 'clsx'
import { useCallback } from 'react'
import { FieldErrors, UseFormRegister } from 'react-hook-form'
import { CardButton } from 'src/components/Button'
import NumericalInput from 'src/components/Input/NumericalInput'
import { MIN_STARTING_MCAP, RECOMMENDED_STARTING_MCAP } from 'src/constants/misc'
import { QUOTE_TOKENS } from 'src/constants/tokens'
import useChainId from 'src/hooks/useChainId'
import { useLiquidityForm } from 'src/hooks/useLaunchForm'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseFormatedAmount } from 'src/utils/amount'
import { currencyInput } from 'src/utils/zod'
import { getChecksumAddress } from 'starknet'
import { z } from 'zod'

import * as styles from './style.css'

// zod schemes

export const liquiditySchema = z.object({
  startingMcap: currencyInput.refine((input) => +parseFormatedAmount(input) >= MIN_STARTING_MCAP, {
    message: `Market cap cannot fall behind $${MIN_STARTING_MCAP.toLocaleString()}`,
  }),
})

export function useLiquidityTemplateForm<T extends z.infer<typeof liquiditySchema>>() {
  const { startingMcap, setStartingMcap } = useLiquidityForm()

  const submit = useCallback(
    (data: T) => {
      setStartingMcap(data.startingMcap)
    },
    [setStartingMcap]
  )

  return { submit, defaultValues: { startingMcap: startingMcap ?? undefined } }
}

interface LiquidityTemplateProps {
  register: UseFormRegister<z.infer<typeof liquiditySchema> & z.infer<any>>
  errors: FieldErrors<z.infer<typeof liquiditySchema>>
}

export default function LiquidityTemplate({ register, errors }: LiquidityTemplateProps) {
  const chainId = useChainId()
  const { quoteTokenAddress, setQuoteTokenAddress } = useLiquidityForm()

  console.log(quoteTokenAddress)

  return (
    <>
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

      <Column gap="8">
        <Text.HeadlineSmall>Quote Token</Text.HeadlineSmall>

        <Row gap="16" flexWrap="wrap">
          {chainId &&
            Object.values(QUOTE_TOKENS[chainId]).map((token) => (
              <CardButton
                key={token.symbol}
                type="button"
                onClick={() => setQuoteTokenAddress(getChecksumAddress(token.address))}
                className={clsx(
                  styles.quoteTokenCard({ selected: getChecksumAddress(token.address) === quoteTokenAddress })
                )}
                title={token.symbol}
                subtitle={token.name}
                icon={() => token.icon}
              />
            ))}
        </Row>
      </Column>
    </>
  )
}
