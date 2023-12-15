import clsx from 'clsx'
import React, { forwardRef, useEffect, useState } from 'react'
import Box, { BoxProps } from 'src/theme/components/Box'

import * as styles from './style.css'

const formatNumber = (value: string) => {
  const numericValue = parseFloat(value.replace(/[^0-9.]/g, ''))
  if (isNaN(numericValue)) return ''

  return new Intl.NumberFormat('en-US', {
    style: 'decimal',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(numericValue)
}

type NumberInputProps = {
  addon?: React.ReactNode
} & BoxProps

const NumberInput = forwardRef<HTMLInputElement, NumberInputProps>(
  ({ addon, className, value, onChange, onBlur, ...props }, ref) => {
    const [inputValue, setInputValue] = useState('')
    useEffect(() => {
      if (value !== undefined && value !== null) {
        setInputValue(formatNumber(value.toString()))
      }
    }, [value])

    const handleInputEvent = (event: React.ChangeEvent<HTMLInputElement>) => {
      setInputValue(event.target.value.replace(/[^0-9.]/g, ''))
      onChange && onChange(event)
    }
    const handleBlurEvent = (event: React.FocusEvent<HTMLInputElement>) => {
      setInputValue(formatNumber(event.target.value))
      onBlur && onBlur(event)
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
          onBlur={handleBlurEvent}
        />
      </Box>
    )
  }
)

NumberInput.displayName = 'NumberInput'

export default NumberInput
