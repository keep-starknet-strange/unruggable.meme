import { Percent } from '@uniswap/sdk-core'
import { BoxProps } from 'src/theme/components/Box'

export enum Safety {
  SAFE,
  CORRECT,
  DANGEROUS,
}

export const TEAM_ALLOCATION_SAFETY_BOUNDS = {
  [Safety.SAFE]: new Percent(0),
  [Safety.CORRECT]: new Percent(10, 100),
}

export const SAFETY_COLORS: { [safety in Safety]: BoxProps['color'] } = {
  [Safety.SAFE]: 'accent',
  [Safety.CORRECT]: 'text1',
  [Safety.DANGEROUS]: 'error',
}
