import { useCallback, useMemo, useState } from 'react'
import { AMM } from 'src/constants/misc'
import { useLaunch } from 'src/hooks/useLaunchForm'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'
import * as Text from 'src/theme/components/Text'

import { LastFormPageProps, Submit } from '../common'
import EkuboLaunch from './Ekubo'
import JediswapLaunch from './Jediswap'
import * as styles from './style.css'

export default function ConfirmForm({ previous }: LastFormPageProps) {
  const [selectedAmm, setSelectedAmm] = useState(AMM.EKUBO)
  const { launch } = useLaunch()

  // AMM selection
  const nextAmm = useCallback(
    () =>
      setSelectedAmm((state) => {
        const Amms = Object.values(AMM)
        const currentIndex = Amms.indexOf(state)

        return currentIndex + 1 >= Amms.length ? Amms[0] : Amms[currentIndex + 1]
      }),
    []
  )
  const previousAmm = useCallback(
    () =>
      setSelectedAmm((state) => {
        const Amms = Object.values(AMM)
        const currentIndex = Amms.indexOf(state)

        return currentIndex - 1 < 0 ? Amms[Amms.length - 1] : Amms[currentIndex - 1]
      }),
    []
  )

  // launch
  const LaunchComponent = useMemo(
    () =>
      ({
        [AMM.EKUBO]: EkuboLaunch,
        [AMM.JEDISWAP]: JediswapLaunch,
      }[selectedAmm]),
    [selectedAmm]
  )

  return (
    <Column gap="42">
      <Text.Custom color="text2" fontWeight="normal" fontSize="24">
        {selectedAmm}
      </Text.Custom>

      <Row className={styles.ammContainer}>
        <Column className={styles.ammNavigatior} onClick={previousAmm}>
          <Icons.CarretRight width="16" transform="rotate(180)" />
        </Column>

        <Box flex="1">
          <LaunchComponent />
        </Box>

        <Column className={styles.ammNavigatior} onClick={nextAmm}>
          <Icons.CarretRight width="16" />
        </Column>
      </Row>

      <Column gap="42">
        <Submit
          previous={previous}
          nextText={selectedAmm === AMM.EKUBO ? 'Coming soon' : `Launch on ${selectedAmm}`}
          onNext={launch ?? undefined}
          disableNext={!launch || selectedAmm === AMM.EKUBO}
        />
      </Column>
    </Column>
  )
}
