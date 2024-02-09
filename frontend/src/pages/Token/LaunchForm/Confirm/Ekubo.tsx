import { useCallback } from 'react'
import { useHodlLimitForm, useLiquidityForm } from 'src/hooks/useLaunchForm'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

export function useEkuboLaunch() {
  return useCallback(() => {
    console.log('ekubo')
  }, [])
}

export default function EkuboLaunch() {
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { liquidityLockPeriod, startingMcap } = useLiquidityForm()

  return (
    <Column gap="32">
      <Column gap="8">
        <Row justifyContent="space-between">
          <Text.Body>Liquidity:</Text.Body>
          <Text.Body color="accent">Free</Text.Body>
        </Row>

        <Row justifyContent="space-between">
          <Text.Body>Team allocation:</Text.Body>
          <Text.Body>2 ETH</Text.Body>
        </Row>
      </Column>

      <Row justifyContent="space-between">
        <Text.HeadlineSmall>Total:</Text.HeadlineSmall>
        <Text.HeadlineSmall>2 ETH</Text.HeadlineSmall>
      </Row>
    </Column>
  )
}
