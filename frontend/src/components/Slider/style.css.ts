import { style } from '@vanilla-extract/css'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

export const slider = style([
  {
    WebkitAppearance: 'none',
    borderRadius: '2px',

    '::before': {
      content: '""',
      height: '8px',
      background: 'linear-gradient(135deg, #8e2de2 0, #4a00e0 100%)',
      borderRadius: '2px',
      left: '0',
      right: '0',
      position: 'absolute',
      display: 'block',
      zIndex: '-1',
    },

    '::-webkit-slider-thumb': {
      background: vars.color.accent,
      borderRadius: '2px',
      width: '12px',
      WebkitAppearance: 'none',
      height: '20px',
      cursor: 'pointer',
    },

    '::-moz-range-thumb': {
      background: vars.color.accent,
    },
  },
  sprinkles({
    width: 'full',
    height: '8',
    outline: 'none',
    position: 'relative',
  }),
])
