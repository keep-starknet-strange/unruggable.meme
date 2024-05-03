import { Safety } from 'core/constants'
import { BoxProps } from 'src/theme/components/Box'

export const SAFETY_COLORS: { [safety in Safety]: BoxProps['color'] } = {
  [Safety.SAFE]: 'accent',
  [Safety.CORRECT]: 'text1',
  [Safety.DANGEROUS]: 'error',
  [Safety.UNKNOWN]: 'text2',
}
