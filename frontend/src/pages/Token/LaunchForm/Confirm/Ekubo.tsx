import { Fraction, Percent } from '@uniswap/sdk-core'
import { useCallback, useEffect } from 'react'
import { useHodlLimitForm, useLaunch, useLiquidityForm } from 'src/hooks/useLaunchForm'
import { NotLaunchedMemecoin } from 'src/hooks/useMemecoin'
import { useWeiAmountToParsedFiatValue } from 'src/hooks/usePrice'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { formatCurrenyAmount, formatPercentage } from 'src/utils/amount'

import * as styles from './style.css'

interface EkuboLaunchProps {
  memecoinInfos: NotLaunchedMemecoin
  teamAllocationTotalPercentage: Percent
}

export default function EkuboLaunch({ memecoinInfos, teamAllocationTotalPercentage }: EkuboLaunchProps) {
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { liquidityLockPeriod, startingMcap } = useLiquidityForm()

  // eth price
  const weiAmountToParsedFiatValue = useWeiAmountToParsedFiatValue()

  // team allocation buyout
  const teamAllocationBuyoutAmount = new Fraction(0)

  // launch
  const launch = useCallback(() => {
    console.log('ekubo')
  }, [])

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
          <Text.Medium color="accent">Free</Text.Medium>
        </Row>

        <Row className={styles.amountRowContainer}>
          <Text.Medium>Team allocation ({formatPercentage(teamAllocationTotalPercentage)})</Text.Medium>
          <Row className={styles.amountContainer}>
            <Text.Subtitle>{weiAmountToParsedFiatValue(teamAllocationBuyoutAmount)}</Text.Subtitle>
            <Text.Body>
              {teamAllocationBuyoutAmount
                ? `${formatCurrenyAmount(teamAllocationBuyoutAmount, { fixed: 4 })} ETH`
                : '-'}
            </Text.Body>
          </Row>
        </Row>
      </Column>

      <Box className={styles.separator} />

      <Row className={styles.amountRowContainer}>
        <Text.Medium>Total</Text.Medium>
        <Row className={styles.amountContainer}>
          <Text.Subtitle>{weiAmountToParsedFiatValue(teamAllocationBuyoutAmount)}</Text.Subtitle>
          <Text.Body>
            {teamAllocationBuyoutAmount ? `${formatCurrenyAmount(teamAllocationBuyoutAmount, { fixed: 4 })} ETH` : '-'}
          </Text.Body>
        </Row>
      </Row>
    </Column>
  )
}
