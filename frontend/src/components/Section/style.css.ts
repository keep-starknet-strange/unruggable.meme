import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const wrapper = style([
  sprinkles({
    width: 'full',
    justifyContent: 'center',
    paddingX: '12',
    paddingTop: {
      sm: '20',
      md: '64',
    },
    paddingBottom: {
      sm: '88',
      md: '32',
    },
  }),
])
