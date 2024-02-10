import { keyframes, style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const inputLabel = sprinkles({
  marginLeft: '8',
  fontWeight: 'medium',
})

export const errorContainer = sprinkles({
  paddingX: '8',
  paddingTop: '4',
  color: 'error',
})

const rotateAnimation = keyframes({
  '100%': {
    transform: 'rotate(360deg)',
  },
})

export const loader = style([
  {
    animation: rotateAnimation,
    animationDuration: '2s',
    animationIterationCount: 'infinite',
    animationTimingFunction: 'linear',
  },
  sprinkles({
    marginLeft: '8',
    color: 'text1',
  }),
])

export const percentageSelection = style([
  {
    borderRadius: '4px',
  },
  sprinkles({
    transition: '125',
    cursor: 'pointer',
    background: 'accentAlpha20',
    borderColor: {
      default: 'accentAlpha20',
      hover: 'accent',
    },
    borderWidth: '1px',
    borderStyle: 'solid',
    paddingY: '4',
    paddingX: '8',
    flex: '1',
    textAlign: 'center',
  }),
])
