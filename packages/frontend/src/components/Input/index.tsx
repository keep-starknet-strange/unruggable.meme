import clsx from 'clsx'
import { forwardRef, useEffect, useState } from 'react'
import Box, { BoxProps } from 'src/theme/components/Box'

import * as styles from './style.css'

interface InputProps extends BoxProps {
  addon?: React.ReactNode
}

const Input = forwardRef<HTMLElement, InputProps>(function ({ addon, className, ...props }, ref) {
  return (
    <Box className={clsx(className, styles.inputContainer)}>
      <Box as="input" className={styles.input} {...props} ref={ref} />
      {addon}
    </Box>
  )
})

Input.displayName = 'Input'
export default Input

// Formattable Input

export interface FormattableInputProps extends BoxProps {
  addon?: React.ReactNode
  formatInput: (value: string) => string | undefined
}

const FormattableInput = forwardRef<HTMLInputElement, FormattableInputProps>(
  ({ addon, className, value, onChange, formatInput, ...props }, ref) => {
    const [inputValue, setInputValue] = useState('')
    useEffect(() => {
      if (value !== undefined && value !== null) {
        const newValue = formatInput(value.toString())
        if (newValue === undefined) return

        setInputValue(newValue)
      }
    }, [value, formatInput])

    const handleInputEvent = (event: React.ChangeEvent<HTMLInputElement>) => {
      const newValue = formatInput(event.target.value)
      if (newValue === undefined) return

      setInputValue(newValue)
      onChange && onChange(event)
    }

    return (
      <Box className={clsx(styles.inputContainer, className)}>
        {addon}
        <Box
          as="input"
          type="text"
          {...props}
          ref={ref}
          className={styles.input}
          value={inputValue}
          onChange={handleInputEvent}
        />
      </Box>
    )
  },
)

FormattableInput.displayName = 'FormattableInput'
export { FormattableInput }
