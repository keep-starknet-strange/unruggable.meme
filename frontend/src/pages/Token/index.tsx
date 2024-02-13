import { Eye } from 'lucide-react'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { useMatch } from 'react-router-dom'
import { PrimaryButton } from 'src/components/Button'
import Section from 'src/components/Section'
import { LiquidityType } from 'src/constants/misc'
import { LaunchedMemecoin, useMemecoinInfos, useMemecoinliquidityLockPosition } from 'src/hooks/useMemecoin'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { vars } from 'src/theme/css/sprinkles.css'
import { getChecksumAddress } from 'starknet'

import CollectFees from './CollectFees'
import ConfirmForm from './LaunchForm/Confirm'
import HodlLimitForm from './LaunchForm/HodlLimit'
import LiquidityForm from './LaunchForm/Liqiudity'
import TeamAllocationForm from './LaunchForm/TeamAllocation'
import TokenMetrics from './Metrics'
import * as styles from './style.css'

export default function TokenPage() {
  const [launchFormPageIndex, setLaunchFormPageIndex] = useState(0)

  // URL
  const match = useMatch('/token/:address')
  const memecoinAddress = useMemo(() => {
    if (match?.params.address) {
      return getChecksumAddress(match?.params.address)
    } else {
      return null
    }
  }, [match?.params.address])

  // form pages
  const next = useCallback(() => setLaunchFormPageIndex((page) => page + 1), [])
  const previous = useCallback(() => setLaunchFormPageIndex((page) => page - 1), [])

  // get memecoin infos
  const [{ data: memecoinInfos, error, indexing }, getMemecoinInfos] = useMemecoinInfos()

  useEffect(() => {
    if (memecoinAddress) {
      getMemecoinInfos(memecoinAddress)
    }
  }, [getMemecoinInfos, memecoinAddress])

  // get memecoin launch status
  const liquidityLockPosition = useMemecoinliquidityLockPosition(
    memecoinInfos?.launch?.liquidityType,
    memecoinInfos?.launch?.liquidityLockManager,
    {
      lockPosition: memecoinInfos?.launch?.liquidityLockPosition,
      ekuboId: memecoinInfos?.launch?.liquidityEkuboId,
    }
  )

  // page content
  const mainContent = useMemo(() => {
    if (indexing) {
      return <Text.Body textAlign="center">Indexing...</Text.Body>
    }

    if (error) {
      return <Text.Body textAlign="center">This token is not unruggable</Text.Body>
    }

    if (!memecoinInfos) return

    return <TokenMetrics memecoinInfos={memecoinInfos} liquidityLockPosition={liquidityLockPosition} />
  }, [indexing, error, memecoinInfos, liquidityLockPosition])

  // Owner content

  const ownerContent = useMemo(() => {
    if (!memecoinInfos || error) return

    const onlyVisibleToYou = (
      <Row gap="2">
        <Eye color={vars.color.text2} height="16px" />
        <Text.Small color="text2">Only visible to you</Text.Small>
      </Row>
    )

    if (liquidityLockPosition?.isOwner) {
      return (
        <>
          {memecoinInfos.launch?.liquidityType === LiquidityType.NFT && (
            <Box className={styles.container}>
              <Column gap="32">
                <CollectFees
                  memecoinInfos={memecoinInfos as LaunchedMemecoin}
                  liquidityLockPosition={liquidityLockPosition}
                />
                {onlyVisibleToYou}
              </Column>
            </Box>
          )}

          <Box className={styles.container}>
            <Column gap="32">
              <PrimaryButton>Increase liquidity lock</PrimaryButton>
              {onlyVisibleToYou}
            </Column>
          </Box>
        </>
      )
    } else if (memecoinInfos.isOwner) {
      return (
        <Box className={styles.container}>
          <Column gap="32">
            <Column>
              <Row gap="12" justifyContent="space-between">
                <Text.HeadlineLarge>Launch token</Text.HeadlineLarge>
              </Row>

              {launchFormPageIndex === 0 && <HodlLimitForm next={next} />}

              {launchFormPageIndex === 1 && <LiquidityForm next={next} previous={previous} />}

              {launchFormPageIndex === 2 && (
                <TeamAllocationForm next={next} previous={previous} memecoinInfos={memecoinInfos} />
              )}

              {launchFormPageIndex === 3 && <ConfirmForm previous={previous} memecoinInfos={memecoinInfos} />}
            </Column>

            {onlyVisibleToYou}
          </Column>
        </Box>
      )
    }

    return
  }, [memecoinInfos, error, liquidityLockPosition, launchFormPageIndex, next, previous])

  return (
    <Section>
      <Column gap="32" alignItems="center" width="full">
        <Box className={styles.container}>{mainContent}</Box>
        {!!ownerContent && <>{ownerContent}</>}
      </Column>
    </Section>
  )
}
