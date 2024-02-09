import { useCallback, useMemo, useState } from 'react'
import { AMM } from 'src/constants/misc'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'
import * as Text from 'src/theme/components/Text'

import { LastFormPageProps, Submit } from '../common'
import EkuboLaunch, { useEkuboLaunch } from './Ekubo'
import JediswapLaunch, { useJediswapLaunch } from './Jediswap'
import * as styles from './style.css'

export default function ConfirmForm({ previous }: LastFormPageProps) {
  const [selectedAMM, setSelectedAMM] = useState(AMM.EKUBO)

  const nextAMM = useCallback(
    () =>
      setSelectedAMM((state) => {
        const AMMs = Object.values(AMM)
        const currentIndex = AMMs.indexOf(state)

        return currentIndex + 1 >= AMMs.length ? AMMs[0] : AMMs[currentIndex + 1]
      }),
    []
  )
  const previousAMM = useCallback(
    () =>
      setSelectedAMM((state) => {
        const AMMs = Object.values(AMM)
        const currentIndex = AMMs.indexOf(state)

        return currentIndex - 1 < 0 ? AMMs[AMMs.length - 1] : AMMs[currentIndex - 1]
      }),
    []
  )

  const ekuboLaunch = useEkuboLaunch()
  const jediswapLaunch = useJediswapLaunch()

  const { Component: LaunchComponent, launch } = useMemo(
    () =>
      ({
        [AMM.EKUBO]: {
          Component: EkuboLaunch,
          launch: ekuboLaunch,
        },
        [AMM.JEDISWAP]: {
          Component: JediswapLaunch,
          launch: jediswapLaunch,
        },
      }[selectedAMM]),
    [selectedAMM, jediswapLaunch, ekuboLaunch]
  )

  return (
    <Column gap="42">
      <Text.Custom color="text2" fontWeight="normal" fontSize="24">
        {selectedAMM}
      </Text.Custom>

      <Row gap="32" padding="12">
        <Column className={styles.AMMNavigatior} onClick={previousAMM}>
          <Icons.CarretRight width="16" transform="rotate(180)" />
        </Column>

        <Box flex="1">
          <LaunchComponent />
        </Box>

        <Column className={styles.AMMNavigatior} onClick={nextAMM}>
          <Icons.CarretRight width="16" />
        </Column>
      </Row>

      <Column gap="42">
        <Submit previous={previous} nextText={`Launch on ${selectedAMM}`} onNext={launch} />
      </Column>
    </Column>
  )
}
