import { Percent } from '@uniswap/sdk-core'
import moment from 'moment'
import { BoxProps } from 'src/theme/components/Box'

export enum Safety {
  SAFE,
  CORRECT,
  DANGEROUS,
  UNKNOWN,
}

export const TEAM_ALLOCATION_SAFETY_BOUNDS = {
  [Safety.SAFE]: new Percent(0),
  [Safety.CORRECT]: new Percent(10, 100),
}

export const LIQUIDITY_LOCK_SAFETY_BOUNDS = {
  [Safety.SAFE]: moment.duration(100, 'years'),
  [Safety.CORRECT]: moment.duration(3, 'months'),
}

export const SAFETY_COLORS: { [safety in Safety]: BoxProps['color'] } = {
  [Safety.SAFE]: 'accent',
  [Safety.CORRECT]: 'text1',
  [Safety.DANGEROUS]: 'error',
  [Safety.UNKNOWN]: 'text2',
}
