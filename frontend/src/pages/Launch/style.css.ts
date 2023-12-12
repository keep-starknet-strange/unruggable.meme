import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'
import { vars } from 'src/theme/css/vars.css'

export const wrapper = style([
  {
    padding: '68px 8px 0',
  },
  sprinkles({
    width: 'full',
    justifyContent: 'center',
  }),
])

export const container = style([
  {
    padding: '16px 12px 12px',
  },
  sprinkles({
    maxWidth: '480',
    width: 'full',
    background: 'bg2',
    borderRadius: '10',
  }),
])

export const deployButton = style([
  {
    background: vars.color.vibrantGradient,
  },
  sprinkles({
    fontSize: '24',
    fontWeight: 'bold',
  }),
])

export const inputLabel = sprinkles({
  marginLeft: '8',
  fontWeight: 'medium',
})
