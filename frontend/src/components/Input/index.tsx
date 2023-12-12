import clsx from 'clsx'
import { forwardRef } from 'react'
import Box, { BoxProps } from 'src/theme/components/Box'

import * as styles from './style.css'

type InputProps = {
  addon?: React.ReactNode
} & BoxProps

const Input = forwardRef(function ({ addon, className, ...props }: InputProps, ref) {
  return (
    <Box className={clsx(className, styles.inputContainer)}>
      <Box as="input" className={styles.input} {...props} ref={ref} />
      {addon}
    </Box>
  )
})

Input.displayName = 'Input'
export default Input
