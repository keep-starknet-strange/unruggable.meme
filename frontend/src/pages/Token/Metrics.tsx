import { Fraction, Percent } from '@uniswap/sdk-core'
import moment from 'moment'
import { useMemo } from 'react'
import { QUOTE_TOKENS } from 'src/constants/contracts'
import { FOREVER } from 'src/constants/misc'
import { Safety, SAFETY_COLORS } from 'src/constants/safety'
import useChainId from 'src/hooks/useChainId'
import { MemecoinInfos, useMemecoinliquidityLockPosition } from 'src/hooks/useMemecoin'
import { useEtherPrice } from 'src/hooks/usePrice'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { decimalsScale } from 'src/utils/decimalScale'
import { parseMonthsDuration } from 'src/utils/moment'
import {
  getLiquidityLockSafety,
  getQuoteTokenSafety,
  getStartingMcapSafety,
  getTeamAllocationSafety,
} from 'src/utils/safety'

import * as styles from './style.css'

interface TokenMetricsProps {
  memecoinInfos: MemecoinInfos
}

export default function TokenMetrics({ memecoinInfos }: TokenMetricsProps) {
  // get memecoin launch status
  const liquidityLockPosition = useMemecoinliquidityLockPosition(
    memecoinInfos?.launch?.liquidityType,
    memecoinInfos?.launch?.liquidityLockManager,
    memecoinInfos?.launch?.liquidityLockPosition
  )

  // eth price
  const ethPriceAtLaunch = useEtherPrice(
    memecoinInfos?.launch?.blockNumber ? memecoinInfos?.launch?.blockNumber - 1 : undefined
  )

  // starknet
  const chainId = useChainId()

  // parse memecoin infos
  const parsedMemecoinInfos = useMemo(() => {
    if (!memecoinInfos) return

    const ret: Record<string, { parsedValue: string; safety: Safety }> = {}

    // team allocation
    const teamAllocation = new Percent(memecoinInfos.teamAllocation, memecoinInfos.totalSupply)

    ret.teamAllocation = {
      parsedValue: `${teamAllocation.toFixed()}%`,
      safety: getTeamAllocationSafety(teamAllocation),
    }

    // liquidity lock
    if (liquidityLockPosition?.unlockTime) {
      const liquidityLock = moment.duration(
        moment(moment.unix(liquidityLockPosition.unlockTime)).diff(moment.now()),
        'milliseconds'
      )
      const safety = getLiquidityLockSafety(liquidityLock)

      ret.liquidityLock = {
        parsedValue: safety === Safety.SAFE ? FOREVER : parseMonthsDuration(liquidityLock),
        safety,
      }
    }

    // quote token
    if (chainId && memecoinInfos?.launch) {
      const quoteTokenInfos = QUOTE_TOKENS[chainId][memecoinInfos.launch.quoteToken]

      ret.quoteToken = {
        parsedValue: quoteTokenInfos?.symbol ?? 'UNKOWN',
        safety: getQuoteTokenSafety(!quoteTokenInfos),
      }
    }

    // starting mcap
    if (memecoinInfos?.launch?.quoteAmount && ethPriceAtLaunch) {
      const startingMcap =
        ret.quoteToken.safety === Safety.SAFE
          ? new Fraction(memecoinInfos?.launch?.quoteAmount)
              .multiply(new Fraction(memecoinInfos.teamAllocation, memecoinInfos.totalSupply).add(1))
              .divide(decimalsScale(18))
              .multiply(ethPriceAtLaunch)
          : undefined

      ret.startingMcap = {
        parsedValue: startingMcap ? `$${startingMcap.toFixed(0, { groupSeparator: ',' })}` : 'UNKNOWN',
        safety: getStartingMcapSafety(teamAllocation, startingMcap),
      }
    }

    return ret
  }, [liquidityLockPosition?.unlockTime, memecoinInfos, chainId, ethPriceAtLaunch])

  // page content
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
            <Text.HeadlineMedium color={SAFETY_COLORS[parsedMemecoinInfos?.teamAllocation?.safety ?? Safety.UNKNOWN]}>
              {parsedMemecoinInfos?.teamAllocation?.parsedValue ?? 'Loading...'}
            </Text.HeadlineMedium>
          </Column>
        </Box>

        <Box className={styles.card} opacity={memecoinInfos.isLaunched ? '1' : '0.5'}>
          <Column gap="8" alignItems="flex-start">
            <Text.Small>Liquidity lock:</Text.Small>
            <Text.HeadlineMedium
              color={SAFETY_COLORS[parsedMemecoinInfos?.liquidityLock?.safety ?? Safety.UNKNOWN]}
              whiteSpace="nowrap"
            >
              {parsedMemecoinInfos?.liquidityLock?.parsedValue ?? 'Not launched'}
            </Text.HeadlineMedium>
          </Column>
        </Box>

        <Box className={styles.card} opacity={memecoinInfos.isLaunched ? '1' : '0.5'}>
          <Column gap="8" alignItems="flex-start">
            <Text.Small>Quote token:</Text.Small>
            <Text.HeadlineMedium
              color={SAFETY_COLORS[parsedMemecoinInfos?.quoteToken?.safety ?? Safety.UNKNOWN]}
              whiteSpace="nowrap"
            >
              {parsedMemecoinInfos?.quoteToken?.parsedValue ?? 'Not launched'}
            </Text.HeadlineMedium>
          </Column>
        </Box>

        <Box className={styles.card} opacity={memecoinInfos.isLaunched ? '1' : '0.5'}>
          <Column gap="8" alignItems="flex-start">
            <Text.Small>Starting market cap:</Text.Small>
            <Text.HeadlineMedium
              color={SAFETY_COLORS[parsedMemecoinInfos?.startingMcap?.safety ?? Safety.UNKNOWN]}
              whiteSpace="nowrap"
            >
              {parsedMemecoinInfos?.startingMcap?.parsedValue ?? 'Not launched'}
            </Text.HeadlineMedium>
          </Column>
        </Box>
      </Row>
    </Column>
  )
}
