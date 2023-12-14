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

export const inputContainer = sprinkles({
  display: 'flex',
  alignItems: 'center',
  borderRadius: '10',
  borderWidth: '1px',
  borderStyle: 'solid',
  overflow: 'hidden',
  padding: '12',
  fontSize: '16',
  color: 'white',
  borderColor: {
    default: 'border1',
    hover: 'accent',
  },
  gap: '8',
  transitionDuration: '125',
  backgroundColor: 'bg1',
})

export const input = sprinkles({
  fontSize: '16',
  position: 'relative',
  whiteSpace: 'nowrap',
  outline: 'none',
  color: {
    default: 'text1',
    placeholder: 'text2',
  },
  background: 'none',
  border: 'none',
  width: 'full',
})
