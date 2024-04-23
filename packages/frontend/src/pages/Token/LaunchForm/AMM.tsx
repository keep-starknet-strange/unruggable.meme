import { useCallback } from 'react'
import { CardButton } from 'src/components/Button'
import { AMM } from 'src/constants/AMMs'
import { AmmInfos } from 'src/constants/AMMs'
import { useAmm } from 'src/hooks/useLaunchForm'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import { FormPageProps } from './common'

// eslint-disable-next-line import/no-unused-modules
export default function AMMForm({ next }: FormPageProps) {
  const [, setAmm] = useAmm()

  const selectAmm = useCallback(
    (amm: AMM) => {
      setAmm(amm)
      next()
    },
    [next, setAmm],
  )

  return (
    <Column gap="42">
      <Text.Custom color="text2" fontWeight="normal" fontSize="24">
        Choose an AMM
      </Text.Custom>

      <Column gap="32">
        <Column gap="16">
          {Object.values(AMM).map((amm) => (
            <CardButton
              key={amm}
              onClick={() => selectAmm(amm)}
              title={amm}
              subtitle={AmmInfos[amm].description}
              icon={() => AmmInfos[amm].icon}
            />
          ))}
        </Column>
      </Column>
    </Column>
  )
}
