import { style } from '@vanilla-extract/css'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

export const container = style([
  {
    maxWidth: '720px',
    boxShadow: `0 0 16px ${vars.color.bg1}`,
  },
  sprinkles({
    width: 'full',
    height: 'full',
    color: 'text1',
    background: 'bg2',
    borderRadius: '10',
    paddingX: '24',
    paddingY: '24',
  }),
])
