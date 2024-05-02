import { Fraction, Percent } from '@uniswap/sdk-core'
import { DECIMALS } from 'core/constants'
import { PlusIcon } from 'lucide-react'
import { useMemo } from 'react'
import { Holder } from 'src/state/launch'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { formatPercentage, parseFormatedAmount } from 'src/utils/amount'
import { decimalsScale } from 'src/utils/decimals'

import * as styles from './style.css'

interface HolderSlotProps {
  holder?: Holder
  totalSupply: string
  open: () => void
}

export default function HolderSlot({ holder, open, totalSupply }: HolderSlotProps) {
  const isEmpty = !holder

  const supplyPercentage = useMemo(
    () =>
      holder
        ? new Percent(parseFormatedAmount(holder?.amount), new Fraction(totalSupply, decimalsScale(DECIMALS)).quotient)
        : undefined,
    [holder, totalSupply],
  )

  return (
    <Column className={styles.slot({ empty: isEmpty })} onClick={open}>
      {supplyPercentage ? (
        <Text.HeadlineMedium textAlign="center">{formatPercentage(supplyPercentage)}</Text.HeadlineMedium>
      ) : (
        <PlusIcon />
      )}
    </Column>
  )
}
