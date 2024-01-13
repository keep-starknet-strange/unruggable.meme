import { zodResolver } from '@hookform/resolvers/zod'
import { Percent } from '@uniswap/sdk-core'
import { Eye } from 'lucide-react'
import moment from 'moment'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { useForm } from 'react-hook-form'
import { useMatch } from 'react-router-dom'
import { PrimaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import NumericalInput from 'src/components/Input/NumericalInput'
import PercentInput from 'src/components/Input/PercentInput'
import Section from 'src/components/Section'
import Slider from 'src/components/Slider'
import Toggler from 'src/components/Toggler'
import {
  LiquidityType,
  MAX_TRANSFER_RESTRICTION_DELAY,
  MIN_STARTING_MCAP,
  MIN_TRANSFER_RESTRICTION_DELAY,
  TRANSFER_RESTRICTION_DELAY_STEP,
} from 'src/constants/misc'
import { useMemecoinInfos } from 'src/hooks/useMemecoin'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { vars } from 'src/theme/css/sprinkles.css'
import { parseFormatedAmount } from 'src/utils/amount'
import { parseDuration } from 'src/utils/moment'
import { currencyInput, percentInput } from 'src/utils/zod'
import { getChecksumAddress } from 'starknet'
import { z } from 'zod'

import * as styles from './style.css'

// zod schemes

const ekuboSchema = z.object({
  hodlLimit: percentInput,
  startingMarketCap: currencyInput.refine((input) => +parseFormatedAmount(input) >= MIN_STARTING_MCAP, {
    message: `Market cap cannot fall behind $${MIN_STARTING_MCAP.toLocaleString()}`,
  }),
})

const jediswapSchema = z.object({
  hodlLimit: percentInput,
})

export default function TokenPage() {
  const [transferRestrictionDelay, setTransferRestrictionDelay] = useState(MIN_TRANSFER_RESTRICTION_DELAY)
  const [liquidityTypeIndex, setLiquidityTypeIndex] = useState(0)

  // URL
  const match = useMatch('/token/:address')
  const collectionAddress = useMemo(() => {
    if (match?.params.address) {
      return getChecksumAddress(match?.params.address)
    } else {
      return null
    }
  }, [match?.params.address])

  // get memecoin infos
  const [{ data: memecoinInfos, error, indexing }, getMemecoinInfos] = useMemecoinInfos()

  useEffect(() => {
    if (collectionAddress) {
      getMemecoinInfos(collectionAddress)
    }
  }, [getMemecoinInfos, collectionAddress])

  // form
  const schema = useMemo(() => {
    const liquidityType = Object.values(LiquidityType)[liquidityTypeIndex] as LiquidityType

    switch (liquidityType) {
      case LiquidityType.EKUBO: {
        return ekuboSchema
      }

      case LiquidityType.JEDISWAP: {
        return jediswapSchema
      }
    }
  }, [liquidityTypeIndex])
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<z.infer<typeof ekuboSchema> & z.infer<typeof jediswapSchema>>({
    resolver: zodResolver(schema),
  })

  // launch
  const launch = useCallback(async (data: z.infer<typeof schema>) => {
    console.log(data)
  }, [])

  // page content
  const mainContent = useMemo(() => {
    if (indexing) {
      return <Text.Body textAlign="center">Indexing...</Text.Body>
    }

    if (error) {
      return <Text.Body textAlign="center">This token is not unruggable</Text.Body>
    }

    if (!memecoinInfos) return

    const teamAllocationPercentage = new Percent(memecoinInfos.teamAllocation, memecoinInfos.maxSupply).toFixed()

    return (
      <Column gap="16">
        <Row gap="12" alignItems="baseline">
          <Text.HeadlineLarge>{memecoinInfos.name}</Text.HeadlineLarge>
          <Text.HeadlineSmall color="text2">${memecoinInfos.symbol}</Text.HeadlineSmall>
        </Row>

        <Box className={styles.hr} />

        <Row gap="16" flexWrap="wrap">
          <Box className={styles.card}>
            <Column gap="8" alignItems="flex-start">
              <Text.Small>Team allocation:</Text.Small>
              <Text.HeadlineMedium color={+teamAllocationPercentage ? 'text1' : 'accent'}>
                {teamAllocationPercentage}%
              </Text.HeadlineMedium>
            </Column>
          </Box>

          <Box className={styles.card} opacity={memecoinInfos.launched ? '1' : '0.5'}>
            <Column gap="8" alignItems="flex-start">
              <Text.Small>Liquidity lock:</Text.Small>
              <Text.HeadlineMedium color={memecoinInfos.launched ? 'accent' : 'text2'} whiteSpace="nowrap">
                {memecoinInfos.launched ? 'Forever' : 'Not launched'}
              </Text.HeadlineMedium>
            </Column>
          </Box>
        </Row>
      </Column>
    )
  }, [indexing, error, memecoinInfos])

  const ownerContent = useMemo(() => {
    if (!memecoinInfos?.isOwner) return

    const onlyVisibleToYou = (
      <Row gap="2">
        <Eye color={vars.color.text2} height="16px" />
        <Text.Small color="text2">Only visible to you</Text.Small>
      </Row>
    )

    if (memecoinInfos.launched) {
      return (
        <Column gap="32">
          {onlyVisibleToYou}
          <PrimaryButton>Collect fees</PrimaryButton>
        </Column>
      )
    } else {
      const parsedTransferRestrictionDelay = parseDuration(moment.duration(transferRestrictionDelay, 'minutes'))

      return (
        <Column as="form" onSubmit={handleSubmit(launch)} gap="32">
          <Row gap="12" justifyContent="space-between">
            <Text.HeadlineMedium>Launch token</Text.HeadlineMedium>

            <Toggler index={liquidityTypeIndex} setIndex={setLiquidityTypeIndex} modes={Object.values(LiquidityType)} />
          </Row>

          <Column gap="8">
            <Text.HeadlineSmall>Anti bot period after launch</Text.HeadlineSmall>
            <Slider
              value={transferRestrictionDelay}
              min={MIN_TRANSFER_RESTRICTION_DELAY}
              step={TRANSFER_RESTRICTION_DELAY_STEP}
              max={MAX_TRANSFER_RESTRICTION_DELAY}
              onSlidingChange={setTransferRestrictionDelay}
              addon={<Input value={parsedTransferRestrictionDelay} />}
            />
          </Column>

          <Column gap="8">
            <Text.HeadlineSmall>Hold limit</Text.HeadlineSmall>
            <PercentInput
              addon={<Text.HeadlineSmall>%</Text.HeadlineSmall>}
              placeholder="1.00"
              {...register('hodlLimit')}
            />

            <Box className={styles.errorContainer}>
              {errors.hodlLimit?.message ? <Text.Error>{errors.hodlLimit.message}</Text.Error> : null}
            </Box>
          </Column>

          {LiquidityType.EKUBO === Object.values(LiquidityType)[liquidityTypeIndex] && (
            <Column gap="8">
              <Text.HeadlineSmall>Starting market cap</Text.HeadlineSmall>

              <NumericalInput
                addon={<Text.HeadlineSmall>$</Text.HeadlineSmall>}
                placeholder="420,000.00"
                {...register('startingMarketCap')}
              />

              <Box className={styles.errorContainer}>
                {errors.startingMarketCap?.message ? <Text.Error>{errors.startingMarketCap.message}</Text.Error> : null}
              </Box>
            </Column>
          )}

          <PrimaryButton type="submit" large disabled>
            {/* Launch */}
            Coming soon
          </PrimaryButton>
          {onlyVisibleToYou}
        </Column>
      )
    }
  }, [
    memecoinInfos?.isOwner,
    memecoinInfos?.launched,
    transferRestrictionDelay,
    handleSubmit,
    launch,
    liquidityTypeIndex,
    register,
    errors.startingMarketCap?.message,
    errors.hodlLimit?.message,
  ])

  return (
    <Section>
      <Column gap="32" alignItems="center" width="full">
        <Box className={styles.container}>{mainContent}</Box>
        {!!ownerContent && <Box className={styles.container}>{ownerContent}</Box>}
      </Column>
    </Section>
  )
}
