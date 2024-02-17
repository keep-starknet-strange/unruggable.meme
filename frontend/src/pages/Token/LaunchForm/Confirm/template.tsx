import { Fraction } from '@uniswap/sdk-core'
import { useMemo } from 'react'
import { AMM } from 'src/constants/AMMs'
import { useAmm, useTeamAllocationTotalPercentage } from 'src/hooks/useLaunchForm'
import useMemecoin from 'src/hooks/useMemecoin'
import { useWeiAmountToParsedFiatValue } from 'src/hooks/usePrice'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { formatCurrenyAmount, formatPercentage } from 'src/utils/amount'

import { FormPageProps, Submit } from '../common'
import * as styles from './style.css'

interface LaunchTemplateProps extends FormPageProps {
  liquidityPrice?: Fraction
  teamAllocationPrice?: Fraction
}

export default function LaunchTemplate({ liquidityPrice, teamAllocationPrice, previous, next }: LaunchTemplateProps) {
  const [amm] = useAmm()

  // eth price
  const weiAmountToParsedFiatValue = useWeiAmountToParsedFiatValue()

  // memecoin
  const { data: memecoin } = useMemecoin()

  // team allocation
  const teamAllocationTotalPercentage = useTeamAllocationTotalPercentage(memecoin?.totalSupply)

  // total payout
  const totalPrice = useMemo(
    () =>
      [liquidityPrice, teamAllocationPrice].reduce<Fraction>(
        (acc, price) => acc.add(price ?? new Fraction(0)),
        new Fraction(0)
      ),
    [liquidityPrice, teamAllocationPrice]
  )

  if (!teamAllocationTotalPercentage) return null

  return (
    <Column gap="42">
      <Column gap="24">
        <Column gap="8">
          <Row className={styles.amountRowContainer}>
            <Text.Medium>Liquidity</Text.Medium>
            {liquidityPrice ? (
              <Row className={styles.amountContainer}>
                <Text.Subtitle>{weiAmountToParsedFiatValue(liquidityPrice)}</Text.Subtitle>
                <Text.Body>
                  {liquidityPrice ? `${formatCurrenyAmount(liquidityPrice, { fixed: 4 })} ETH` : '-'}
                </Text.Body>
              </Row>
            ) : (
              <Text.Medium color="accent">Free</Text.Medium>
            )}
          </Row>

          <Row className={styles.amountRowContainer}>
            <Text.Medium>Team allocation ({formatPercentage(teamAllocationTotalPercentage)})</Text.Medium>
            {teamAllocationPrice ? (
              <Row className={styles.amountContainer}>
                <Text.Subtitle>{weiAmountToParsedFiatValue(teamAllocationPrice)}</Text.Subtitle>
                <Text.Body>
                  {teamAllocationPrice ? `${formatCurrenyAmount(teamAllocationPrice, { fixed: 4 })} ETH` : '-'}
                </Text.Body>
              </Row>
            ) : (
              <Text.Medium color="accent">Free</Text.Medium>
            )}
          </Row>
        </Column>

        <Box className={styles.separator} />

        <Row className={styles.amountRowContainer}>
          <Text.Medium>Total</Text.Medium>
          <Row className={styles.amountContainer}>
            <Text.Subtitle>{weiAmountToParsedFiatValue(totalPrice)}</Text.Subtitle>
            <Text.Body>{totalPrice ? `${formatCurrenyAmount(totalPrice, { fixed: 4 })} ETH` : '-'}</Text.Body>
          </Row>
        </Row>
      </Column>

      <Submit
        previous={previous}
        nextText={amm === AMM.EKUBO ? 'Coming soon' : `Launch on ${amm}`}
        onNext={next}
        disableNext={amm === AMM.EKUBO}
      />
    </Column>
  )
}
