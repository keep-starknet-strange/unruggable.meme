import { Percent } from '@uniswap/sdk-core'
import { getLiquidityLockSafety, getQuoteTokenSafety, getStartingMcapSafety, getTeamAllocationSafety } from 'core'
import { QUOTE_TOKENS, Safety } from 'core/constants'
import { useFactory, useQuoteToken, useQuoteTokenPrice } from 'hooks'
import moment from 'moment'
import { useMemo } from 'react'
import { Link, useParams } from 'react-router-dom'
import Dropdown from 'src/components/Dropdown'
import { FOREVER } from 'src/constants/misc'
import { SAFETY_COLORS } from 'src/constants/safety'
import useChainId from 'src/hooks/useChainId'
import useLinks from 'src/hooks/useLinks'
import useMemecoin from 'src/hooks/useMemecoin'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { formatPercentage } from 'src/utils/amount'
import { parseMonthsDuration } from 'src/utils/moment'

import * as styles from './style.css'

export default function TokenMetrics() {
  // memecoin
  const { address: tokenAddress } = useParams()
  const { data: memecoin } = useMemecoin(tokenAddress)

  // dropdown links
  const links = useLinks(memecoin?.address)

  // quote token
  const quoteToken = useQuoteToken(memecoin?.isLaunched ? memecoin?.liquidity?.quoteToken : undefined)

  // quote token price
  const quoteTokenPriceAtLaunch = useQuoteTokenPrice(
    quoteToken?.address,
    memecoin?.isLaunched ? memecoin.launch.blockNumber - 1 : undefined,
  )

  // sdk factory
  const sdkFactory = useFactory()

  // starknet
  const chainId = useChainId()

  // parse memecoin infos
  const parsedMemecoinInfos = useMemo(() => {
    if (!quoteToken?.decimals || !memecoin) return
    if (!memecoin.isLaunched) return {}

    const ret: Record<string, { parsedValue: string; safety: Safety }> = {}

    // team allocation
    const teamAllocation = new Percent(memecoin.launch.teamAllocation.toString(), memecoin.totalSupply.toString())

    ret.teamAllocation = {
      parsedValue: formatPercentage(teamAllocation),
      safety: getTeamAllocationSafety(teamAllocation),
    }

    // liquidity lock
    if (memecoin.liquidity.unlockTime) {
      const liquidityLock = moment.duration(
        moment(moment.unix(memecoin.liquidity.unlockTime)).diff(moment.now()),
        'milliseconds',
      )
      const safety = getLiquidityLockSafety(liquidityLock)

      ret.liquidityLock = {
        parsedValue: safety === Safety.SAFE ? FOREVER : parseMonthsDuration(liquidityLock),
        safety,
      }
    }

    // quote token
    if (chainId) {
      const quoteTokenInfos = QUOTE_TOKENS[chainId][memecoin.liquidity.quoteToken]

      ret.quoteToken = {
        parsedValue: quoteTokenInfos?.symbol ?? 'UNKOWN',
        safety: getQuoteTokenSafety(!quoteTokenInfos),
      }
    }

    // starting mcap
    if (quoteTokenPriceAtLaunch) {
      const startingMcap = sdkFactory.getStartingMarketCap(memecoin, quoteTokenPriceAtLaunch)

      ret.startingMcap = {
        parsedValue: startingMcap ? `$${startingMcap.toFixed(0, { groupSeparator: ',' })}` : 'UNKNOWN',
        safety: getStartingMcapSafety(teamAllocation, startingMcap),
      }
    }

    return ret
  }, [quoteToken?.decimals, memecoin, chainId, quoteTokenPriceAtLaunch, sdkFactory])

  if (!memecoin) return null

  // page content
  return (
    <Column gap="16">
      <Row gap="16" justifyContent="space-between">
        <Row gap="12" alignItems="baseline">
          <Text.HeadlineLarge>{memecoin.name}</Text.HeadlineLarge>
          <Text.HeadlineSmall color="text2">${memecoin.symbol}</Text.HeadlineSmall>
        </Row>

        <Dropdown>
          {(Object.keys(links) as Array<keyof typeof links>).map((name) => {
            const link = links[name]

            if (link) {
              return (
                <Link target="_blank" to={link} key={name}>
                  <Box className={styles.dropdownRow}>
                    <Text.Body style={{ textTransform: 'capitalize' }}>{name}</Text.Body>
                  </Box>
                </Link>
              )
            }

            return <></>
          })}
        </Dropdown>
      </Row>

      <Box className={styles.hr} />

      {memecoin.isLaunched ? (
        <Row gap="16" flexWrap="wrap">
          <Box className={styles.card}>
            <Column gap="8" alignItems="flex-start">
              <Text.Small>Team allocation:</Text.Small>
              <Text.HeadlineMedium color={SAFETY_COLORS[parsedMemecoinInfos?.teamAllocation?.safety ?? Safety.UNKNOWN]}>
                {parsedMemecoinInfos?.teamAllocation?.parsedValue ?? 'Loading'}
              </Text.HeadlineMedium>
            </Column>
          </Box>

          <Box className={styles.card}>
            <Column gap="8" alignItems="flex-start">
              <Text.Small>Liquidity lock:</Text.Small>
              <Text.HeadlineMedium
                color={SAFETY_COLORS[parsedMemecoinInfos?.liquidityLock?.safety ?? Safety.UNKNOWN]}
                whiteSpace="nowrap"
              >
                {parsedMemecoinInfos?.liquidityLock?.parsedValue ?? 'Loading'}
              </Text.HeadlineMedium>
            </Column>
          </Box>

          <Box className={styles.card}>
            <Column gap="8" alignItems="flex-start">
              <Text.Small>Quote token:</Text.Small>
              <Text.HeadlineMedium
                color={SAFETY_COLORS[parsedMemecoinInfos?.quoteToken?.safety ?? Safety.UNKNOWN]}
                whiteSpace="nowrap"
              >
                {parsedMemecoinInfos?.quoteToken?.parsedValue ?? 'Loading'}
              </Text.HeadlineMedium>
            </Column>
          </Box>

          <Box className={styles.card}>
            <Column gap="8" alignItems="flex-start">
              <Text.Small>Starting market cap:</Text.Small>
              <Text.HeadlineMedium
                color={SAFETY_COLORS[parsedMemecoinInfos?.startingMcap?.safety ?? Safety.UNKNOWN]}
                whiteSpace="nowrap"
              >
                {parsedMemecoinInfos?.startingMcap?.parsedValue ?? 'Loading'}
              </Text.HeadlineMedium>
            </Column>
          </Box>
        </Row>
      ) : (
        <Text.HeadlineMedium color={SAFETY_COLORS[Safety.UNKNOWN]}>Not launched</Text.HeadlineMedium>
      )}
    </Column>
  )
}
