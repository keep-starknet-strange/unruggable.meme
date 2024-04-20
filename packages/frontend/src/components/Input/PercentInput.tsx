import { forwardRef, useCallback } from 'react'

import { FormattableInput, FormattableInputProps } from '.'

type PercentInputProps = Omit<FormattableInputProps, 'formatInput'>

const PercentInput = forwardRef<HTMLInputElement, PercentInputProps>(({ ...props }, ref) => {
  const formatNumber = useCallback((value: string) => {
    if (!value.length) return ''

    if (!/^([0-9]+([.][0-9]{0,2})?|[0-9]+)$/.test(value)) return

    return value
  }, [])

  return <FormattableInput {...props} formatInput={formatNumber} ref={ref} />
})

PercentInput.displayName = 'PercentInput'

export default PercentInput
