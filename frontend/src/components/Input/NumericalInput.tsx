import clsx from 'clsx'
import React, { forwardRef, useEffect, useState } from 'react'
import Box, { BoxProps } from 'src/theme/components/Box'

import * as styles from './NumericalInput.css'

const formatNumber = (value: string) => {
  // add 999 at the end to not lose potential `.0` and not shift commas
  const numericValue = parseInt(`${value.replace(/[^0-9]/g, '')}`)
  if (isNaN(numericValue)) return ''

  return new Intl.NumberFormat('en-US', {
    style: 'decimal',
    maximumFractionDigits: 18,
  }).format(numericValue)
}

interface NumberInputProps extends BoxProps {
  addon?: React.ReactNode
}

const NumericalInput = forwardRef<HTMLInputElement, NumberInputProps>(
  ({ addon, className, value, onChange, ...props }, ref) => {
    const [inputValue, setInputValue] = useState('')
    useEffect(() => {
      if (value !== undefined && value !== null) {
        setInputValue(formatNumber(value.toString()))
      }
    }, [value])

    const handleInputEvent = (event: React.ChangeEvent<HTMLInputElement>) => {
      setInputValue(formatNumber(event.target.value))
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
  }
)

NumericalInput.displayName = 'NumericalInput'

export default NumericalInput
