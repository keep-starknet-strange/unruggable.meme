import { Fraction, Percent } from '@uniswap/sdk-core'
import moment from 'moment'
import { useCallback, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { IconButton } from 'src/components/Button'
import { DECIMALS, FOREVER, LiquidityType } from 'src/constants/misc'
import { Safety, SAFETY_COLORS } from 'src/constants/safety'
import { QUOTE_TOKENS } from 'src/constants/tokens'
import useChainId from 'src/hooks/useChainId'
import useLinks from 'src/hooks/useLinks'
import useMemecoin from 'src/hooks/useMemecoin'
import { useQuoteTokenPrice } from 'src/hooks/usePrice'
import useQuoteToken from 'src/hooks/useQuote'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'
import * as Text from 'src/theme/components/Text'
import { formatPercentage } from 'src/utils/amount'
import { decimalsScale } from 'src/utils/decimalScale'
import { getInitialPrice } from 'src/utils/ekubo'
import { parseMonthsDuration } from 'src/utils/moment'
import {
  getLiquidityLockSafety,
  getQuoteTokenSafety,
  getStartingMcapSafety,
  getTeamAllocationSafety,
} from 'src/utils/safety'

import * as styles from './style.css'

export default function TokenMetrics() {
  // TODO: create a dropdown component
  const [dropdownOpened, setDropdownOpened] = useState(false)

  // memecoin
  const { data: memecoin } = useMemecoin()

  // dropdown
  const toggleDropdown = useCallback(() => setDropdownOpened((state) => !state), [])

  // dropdown links
  const links = useLinks(memecoin?.address)

  // quote token
  const quoteToken = useQuoteToken(memecoin?.isLaunched ? memecoin?.liquidity?.quoteToken : undefined)

  // quote token price
  const quoteTokenPriceAtLaunch = useQuoteTokenPrice(
    quoteToken?.address,
    memecoin?.isLaunched ? memecoin.launch.blockNumber - 1 : undefined,
  )

  // starknet
  const chainId = useChainId()

  // parse memecoin infos
  const parsedMemecoinInfos = useMemo(() => {
    if (!quoteToken?.decimals || !memecoin) return
    if (!memecoin.isLaunched) return {}

    const ret: Record<string, { parsedValue: string; safety: Safety }> = {}

    // team allocation
    const teamAllocation = new Percent(memecoin.launch.teamAllocation, memecoin.totalSupply)

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
      let startingMcap: Fraction | undefined
      switch (memecoin.liquidity.type) {
        case LiquidityType.STARKDEFI_ERC20:
        case LiquidityType.JEDISWAP_ERC20: {
          startingMcap =
            ret.quoteToken.safety === Safety.SAFE
              ? new Fraction(memecoin.liquidity.quoteAmount)
                  .multiply(new Fraction(memecoin.launch.teamAllocation, memecoin.totalSupply).add(1))
                  .divide(decimalsScale(quoteToken.decimals))
                  .multiply(quoteTokenPriceAtLaunch)
              : undefined

          break
        }

        case LiquidityType.EKUBO_NFT: {
          const initialPrice = getInitialPrice(memecoin.liquidity.startingTick)
          startingMcap =
            ret.quoteToken.safety === Safety.SAFE
              ? new Fraction(
                  initialPrice.toFixed(DECIMALS).replace(/\./, '').replace(/^0+/, ''), // from 0.000[...]0001 to "1"
                  decimalsScale(DECIMALS),
                )
                  .multiply(quoteTokenPriceAtLaunch)
                  .multiply(memecoin.totalSupply)
                  .divide(decimalsScale(DECIMALS))
              : undefined
        }
      }

      ret.startingMcap = {
        parsedValue: startingMcap ? `$${startingMcap.toFixed(0, { groupSeparator: ',' })}` : 'UNKNOWN',
        safety: getStartingMcapSafety(teamAllocation, startingMcap),
      }
    }

    return ret
  }, [quoteToken?.decimals, memecoin, chainId, quoteTokenPriceAtLaunch])

  if (!memecoin) return null

  // page content
  return (
    <Column gap="16">
      <Row gap="16" justifyContent="space-between">
        <Row gap="12" alignItems="baseline">
          <Text.HeadlineLarge>{memecoin.name}</Text.HeadlineLarge>
          <Text.HeadlineSmall color="text2">${memecoin.symbol}</Text.HeadlineSmall>
        </Row>

        <Box position="relative">
          <IconButton onClick={toggleDropdown} large>
            <Icons.ThreeDots display="block" width="16" />
          </IconButton>

          <Column className={styles.dropdown({ opened: dropdownOpened })}>
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
          </Column>
        </Box>
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
