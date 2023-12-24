import { style } from '@vanilla-extract/css'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

export const wrapper = style([
  {
    padding: '68px 0px',
  },
  sprinkles({
    width: 'full',
    justifyContent: 'center',
  }),
])

export const container = style([
  {
    padding: '16px 12px 12px',
    boxShadow: `0 0 16px ${vars.color.bg1}`,
  },
  sprinkles({
    maxWidth: '480',
    width: 'full',
    background: 'bg1',
    borderRadius: '10',
    border: 'light',
  }),
])

export const inputLabel = sprinkles({
  marginLeft: '8',
  fontWeight: 'medium',
})

export const errorContainer = sprinkles({
  paddingX: '8',
  paddingTop: '4',
  color: 'error',
})
