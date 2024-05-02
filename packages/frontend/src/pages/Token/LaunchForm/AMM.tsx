import { AMM, AMMS } from 'core/constants'
import { useCallback } from 'react'
import { CardButton } from 'src/components/Button'
import { AMM_ICONS } from 'src/constants/icons'
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
              subtitle={AMMS[amm].description}
              icon={() => AMM_ICONS[amm]}
            />
          ))}
        </Column>
      </Column>
    </Column>
  )
}
