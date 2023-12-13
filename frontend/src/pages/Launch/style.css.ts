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
    fontWeight: 'semibold',
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
