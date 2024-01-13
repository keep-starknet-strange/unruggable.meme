import { forwardRef, useCallback } from 'react'

import { FormattableInput, FormattableInputProps } from '.'

type NumericalInputProps = Omit<FormattableInputProps, 'formatInput'>

const NumericalInput = forwardRef<HTMLInputElement, NumericalInputProps>(({ ...props }, ref) => {
  const formatNumber = useCallback((value: string) => {
    const numericValue = parseInt(value.replace(/[^0-9]/g, ''))
    if (isNaN(numericValue)) return ''

    return new Intl.NumberFormat('en-US', {
      style: 'decimal',
      maximumFractionDigits: 18,
    }).format(numericValue)
  }, [])

  return <FormattableInput {...props} formatInput={formatNumber} ref={ref} />
})

NumericalInput.displayName = 'NumericalInput'

export default NumericalInput
