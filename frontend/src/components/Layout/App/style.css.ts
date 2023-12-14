import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const radial = style([
  {
    zIndex: '-1',
  },
  sprinkles({
    position: 'fixed',
    top: '0',
    right: '0',
    left: '0',
    bottom: '0',
    background: 'appGradient',
  }),
])
