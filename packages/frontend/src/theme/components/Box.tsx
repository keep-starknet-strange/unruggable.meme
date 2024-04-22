/* eslint-disable react/display-name */
// Inspired by https://github.com/Uniswap/interface/blob/main/src/nft/components/Box.ts

import clsx, { ClassValue } from 'clsx'
import React from 'react'

import { atoms } from '../css/atoms'
import { Sprinkles, sprinkles } from '../css/sprinkles.css'

type HTMLProperties<T = HTMLElement> = Omit<
  React.AllHTMLAttributes<T>,
  'as' | 'className' | 'color' | 'height' | 'width'
>

interface Props extends Sprinkles, HTMLProperties {
  as?: React.ElementType
  className?: ClassValue
  loading?: boolean
}

const Box = React.forwardRef<HTMLElement, Props>(({ as = 'div', className, loading, ...props }, ref) => {
  const atomProps: Record<string, unknown> = {}
  const nativeProps: Record<string, unknown> = {}

  // filter Native and Sprinkles props
  for (const key in props) {
    if (sprinkles.properties.has(key as keyof Sprinkles)) {
      atomProps[key] = props[key as keyof typeof props]
    } else {
      nativeProps[key] = props[key as keyof typeof props]
    }
  }

  // compute class names
  const atomicClasses = atoms({
    reset: loading ? 'loading' : undefined,
    ...atomProps,
  })

  return React.createElement(as, {
    className: clsx(atomicClasses, className),
    ...nativeProps,
    ref,
  })
})

export default Box

export type BoxProps = Parameters<typeof Box>[0]
