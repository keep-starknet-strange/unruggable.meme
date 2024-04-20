import React from 'react'

import Box, { BoxProps } from './Box'

export const Row = React.forwardRef((props: BoxProps, ref: React.ForwardedRef<HTMLElement>) => {
  return <Box ref={ref} display="flex" flexDirection="row" alignItems="center" {...props} />
})

Row.displayName = 'Row'

export const Column = React.forwardRef((props: BoxProps, ref: React.ForwardedRef<HTMLElement>) => {
  return <Box ref={ref} display="flex" flexDirection="column" {...props} />
})

Column.displayName = 'Row'
