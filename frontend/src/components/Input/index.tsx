import clsx from 'clsx'
import Box, { BoxProps } from 'src/theme/components/Box'

import * as styles from './style.css'

export default function Input({ className, ...props }: BoxProps) {
  return (
    <Box className={clsx(className, styles.inputContainer)}>
      <Box as="input" className={styles.input} {...props} />
    </Box>
  )
}
