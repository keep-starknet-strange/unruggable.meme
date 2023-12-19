import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const noTokensContainer = style([
  sprinkles({
    borderColor: 'text1',
    borderWidth: '1px',
    borderStyle: 'solid',
    width: 'full',
    borderRadius: '10',
    paddingY: '16',
  }),
])

export const container = style([
  {
    maxWidth: '720px',
  },
  sprinkles({
    width: 'full',
    gap: '32',
  }),
])
