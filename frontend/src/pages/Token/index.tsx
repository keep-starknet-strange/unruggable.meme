import { Eye } from 'lucide-react'
import moment from 'moment'
import { useCallback, useMemo, useState } from 'react'
import { useMatch } from 'react-router-dom'
import Section from 'src/components/Section'
import { LiquidityType } from 'src/constants/misc'
import { Safety } from 'src/constants/safety'
import useMemecoin from 'src/hooks/useMemecoin'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { vars } from 'src/theme/css/sprinkles.css'
import { getLiquidityLockSafety } from 'src/utils/safety'
import { getChecksumAddress } from 'starknet'

import CollectFees from './CollectFees'
import IncreaseLiquidityLock from './IncreaseLiquidityLock'
import AMMForm from './LaunchForm/AMM'
import ConfirmForm from './LaunchForm/Confirm'
import HodlLimitForm from './LaunchForm/HodlLimit'
import LiquidityForm from './LaunchForm/Liquidity'
import TeamAllocationForm from './LaunchForm/TeamAllocation'
import TokenMetrics from './Metrics'
import * as styles from './style.css'

export default function TokenPage() {
  const [launchFormPageIndex, setLaunchFormPageIndex] = useState(0)

  // URL
  const match = useMatch('/token/:address')
  const tokenAddress = useMemo(() => {
    if (match?.params.address) {
      return getChecksumAddress(match?.params.address)
    } else {
      return null
    }
  }, [match?.params.address])

  // form pages
  const next = useCallback(() => setLaunchFormPageIndex((page) => page + 1), [])
  const previous = useCallback(() => setLaunchFormPageIndex((page) => page - 1), [])

  // memecoin
  const { data: memecoin, ruggable } = useMemecoin(tokenAddress ?? undefined)

  // page content
  const mainContent = useMemo(() => {
    if (ruggable) {
      return <Text.Body textAlign="center">This token is not unruggable</Text.Body>
    }

    if (!memecoin) return

    return <TokenMetrics />
  }, [ruggable, memecoin])

  // Owner content

  const ownerContent = useMemo(() => {
    if (!memecoin) return

    const onlyVisibleToYou = (
      <Row gap="2">
        <Eye color={vars.color.text2} height="16px" />
        <Text.Small color="text2">Only visible to you</Text.Small>
      </Row>
    )

    if (memecoin.isLaunched && memecoin.isOwner) {
      const liquidityLock = moment.duration(
        moment(moment.unix(memecoin.liquidity.unlockTime)).diff(moment.now()),
        'milliseconds'
      )
      const liquidityLockSafety = getLiquidityLockSafety(liquidityLock)

      return (
        <>
          {memecoin.liquidity.type === LiquidityType.NFT && (
            <Column className={styles.container}>
              <CollectFees />
              {onlyVisibleToYou}
            </Column>
          )}

          {liquidityLockSafety !== Safety.SAFE && (
            <Column className={styles.container}>
              <IncreaseLiquidityLock />
              {onlyVisibleToYou}
            </Column>
          )}
        </>
      )
    } else if (memecoin.isOwner) {
      return (
        <Box className={styles.container}>
          <Column gap="32">
            <Column>
              <Row gap="12" justifyContent="space-between">
                <Text.HeadlineLarge>Launch token</Text.HeadlineLarge>
              </Row>

              {launchFormPageIndex === 0 && <AMMForm next={next} />}

              {launchFormPageIndex === 1 && <LiquidityForm next={next} previous={previous} />}

              {launchFormPageIndex === 2 && <HodlLimitForm next={next} previous={previous} />}

              {launchFormPageIndex === 3 && <TeamAllocationForm next={next} previous={previous} />}

              {launchFormPageIndex === 4 && <ConfirmForm previous={previous} />}
            </Column>

            {onlyVisibleToYou}
          </Column>
        </Box>
      )
    }

    return
  }, [memecoin, launchFormPageIndex, next, previous])

  return (
    <Section>
      <Column gap="32" alignItems="center" width="full">
        <Box className={styles.container}>{mainContent}</Box>
        {!!ownerContent && <>{ownerContent}</>}
      </Column>
    </Section>
  )
}
