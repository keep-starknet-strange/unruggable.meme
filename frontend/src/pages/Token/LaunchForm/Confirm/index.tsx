import { useMemo } from 'react'
import { AMM } from 'src/constants/AMMs'
import { useAmm } from 'src/hooks/useLaunchForm'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import { LastFormPageProps } from '../common'
import EkuboLaunch from './Ekubo'
import StarndardAmmLaunch from './StandardAmm'

export default function ConfirmForm({ previous }: Readonly<LastFormPageProps>) {
  const [amm] = useAmm()

  const launchComponent = useMemo(() => {
    switch (amm) {
      case AMM.EKUBO:
        return <EkuboLaunch previous={previous} />

      case AMM.JEDISWAP:
        return <StarndardAmmLaunch previous={previous} amm={AMM.JEDISWAP} />

      case AMM.STARKDEFI:
        return <StarndardAmmLaunch previous={previous} amm={AMM.STARKDEFI} />
    }
  }, [amm, previous])

  return (
    <Column gap="42">
      <Text.Custom color="text2" fontWeight="normal" fontSize="24">
        Confirm
      </Text.Custom>

      {launchComponent}
    </Column>
  )
}
