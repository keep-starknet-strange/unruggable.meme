import { AMM } from 'core/constants'
import { useMemo } from 'react'
import { useAmm } from 'src/hooks/useLaunchForm'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import { FormPageProps } from '../common'
import EkuboLiquidityForm from './Ekubo'
import StandardAmmLiquidityForm from './StandardAmm'

export default function LiquidityForm({ next, previous }: FormPageProps) {
  const [amm] = useAmm()

  // amm specificities
  const liquidityComponent = useMemo(() => {
    switch (amm) {
      case AMM.EKUBO:
        return <EkuboLiquidityForm previous={previous} next={next} />

      case AMM.JEDISWAP:
        return <StandardAmmLiquidityForm previous={previous} next={next} />

      case AMM.STARKDEFI:
        return <StandardAmmLiquidityForm previous={previous} next={next} />
    }
  }, [amm, next, previous])

  return (
    <Column gap="42">
      <Text.Custom color="text2" fontWeight="normal" fontSize="24">
        Liquidity
      </Text.Custom>

      {liquidityComponent}
    </Column>
  )
}
