import { keyframes, style } from '@vanilla-extract/css'

import { vars } from './sprinkles.css'

const placeholderShimmer = keyframes({
  '0%': {
    backgroundPosition: '100%',
  },
  '66%': {
    backgroundPosition: '-100%',
  },
  '100%': {
    backgroundPosition: '-100%',
  },
})

const loading = style({
  animationDuration: '1s',
  animationFillMode: 'forwards',
  animationIterationCount: 'infinite',
  animationName: placeholderShimmer,
  animationTimingFunction: 'linear',
  backgroundColor: vars.color.bg1,
  backgroundImage: `linear-gradient(to right, #ffffff10 8%, #ffffff08 38%, #ffffff10 54%)`,
  backgroundSize: '200%',
})

export const element = {
  loading,
}
