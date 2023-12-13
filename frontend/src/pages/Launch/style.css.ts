import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'

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
    ':disabled': {
      opacity: '0.5',
    },
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

export const errorContainer = sprinkles({
  paddingX: '8',
  paddingTop: '4',
  color: 'error',
})