import { useContractWrite } from '@starknet-react/core'
import { Fraction } from '@uniswap/sdk-core'
import moment from 'moment'
import { useCallback, useEffect, useMemo } from 'react'
import { ETH_ADDRESS, FACTORY_ADDRESSES } from 'src/constants/contracts'
import { LIQUIDITY_LOCK_FOREVER_TIMESTAMP, MAX_LIQUIDITY_LOCK_PERIOD, Selector } from 'src/constants/misc'
import useChainId from 'src/hooks/useChainId'
import { useHodlLimitForm, useLaunch, useLiquidityForm } from 'src/hooks/useLaunchForm'
import { NotLaunchedMemecoin } from 'src/hooks/useMemecoin'
import { useEtherPrice, useWeiAmountToParsedFiatValue } from 'src/hooks/usePrice'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseCurrencyAmount, parseFormatedAmount } from 'src/utils/amount'
import { decimalsScale } from 'src/utils/decimalScale'
import { CallData, uint256 } from 'starknet'

import * as styles from './style.css'

interface JediswapLaunchProps {
  memecoinInfos: NotLaunchedMemecoin
}

export default function JediswapLaunch({ memecoinInfos }: JediswapLaunchProps) {
  // form data
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { liquidityLockPeriod, startingMcap } = useLiquidityForm()

  // eth price
  const ethPrice = useEtherPrice()
  const weiAmountToParsedFiatValue = useWeiAmountToParsedFiatValue()

  // quote amount
  const quoteAmount = useMemo(() => {
    if (!ethPrice || !startingMcap) return

    // mcap / eth_price * (1 - team_allocation / total_supply)
    return new Fraction(parseFormatedAmount(startingMcap))
      .divide(ethPrice)
      .multiply(new Fraction(1).subtract(new Fraction(0 /* replace by TA */, memecoinInfos.totalSupply)))
  }, [memecoinInfos.totalSupply, startingMcap, ethPrice])

  // starknet
  const chainId = useChainId()
  const { writeAsync } = useContractWrite({})

  // launch
  const launch = useCallback(() => {
    if (!quoteAmount || !chainId || !hodlLimit) return

    const uin256QuoteAmount = uint256.bnToUint256(BigInt(quoteAmount.multiply(decimalsScale(18)).quotient.toString()))

    const approveCalldata = CallData.compile([
      FACTORY_ADDRESSES[chainId], // spender
      uin256QuoteAmount,
    ])

    const launchCalldata = CallData.compile([
      memecoinInfos.address, // memecoin address
      antiBotPeriod * 60, // anti bot period in seconds
      +hodlLimit * 100, // hodl limit
      ETH_ADDRESS, // quote token
      [], // initial holders
      [], // intial holders amounts
      uin256QuoteAmount, // quote amount
      liquidityLockPeriod === MAX_LIQUIDITY_LOCK_PERIOD // liquidity lock until
        ? LIQUIDITY_LOCK_FOREVER_TIMESTAMP
        : moment().add(moment.duration(liquidityLockPeriod, 'months')).unix(),
    ])

    writeAsync({
      calls: [
        {
          contractAddress: ETH_ADDRESS,
          entrypoint: Selector.APPROVE,
          calldata: approveCalldata,
        },
        {
          contractAddress: FACTORY_ADDRESSES[chainId],
          entrypoint: Selector.LAUNCH_ON_JEDISWAP,
          calldata: launchCalldata,
        },
      ],
    })
  }, [quoteAmount, chainId, memecoinInfos.address, antiBotPeriod, hodlLimit, liquidityLockPeriod, writeAsync])

  // set launch
  const [, setLaunch] = useLaunch()
  useEffect(() => {
    setLaunch(launch)
  }, [launch, setLaunch])

  return (
    <Column gap="24">
      <Column gap="8">
        <Row className={styles.amountRowContainer}>
          <Text.Medium>Liquidity</Text.Medium>
          <Row className={styles.amountContainer}>
            <Text.Subtitle>{weiAmountToParsedFiatValue(quoteAmount)}</Text.Subtitle>
            <Text.Body>{quoteAmount ? `${parseCurrencyAmount(quoteAmount, { fixed: 4 })} ETH` : '-'}</Text.Body>
          </Row>
        </Row>

        <Row className={styles.amountRowContainer}>
          <Text.Medium>Team allocation</Text.Medium>
          <Text.Medium color="accent">Free</Text.Medium>
        </Row>
      </Column>

      <Box className={styles.separator} />

      <Row className={styles.amountRowContainer}>
        <Text.Medium>Total</Text.Medium>
        <Row className={styles.amountContainer}>
          <Text.Subtitle>{weiAmountToParsedFiatValue(quoteAmount)}</Text.Subtitle>
          <Text.Body>{quoteAmount ? `${parseCurrencyAmount(quoteAmount, { fixed: 4 })} ETH` : '-'}</Text.Body>
        </Row>
      </Row>
    </Column>
  )
}
