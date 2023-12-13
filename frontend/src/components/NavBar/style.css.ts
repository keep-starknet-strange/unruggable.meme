import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const nav = style([
  sprinkles({
    position: 'sticky',
    top: '0',
    padding: '24',
    zIndex: 'sticky',
  }),
])

export const logoContainer = style([
  {
    ':hover': {
      transform: 'rotate(5deg)',
    },
  },
  sprinkles({
    color: 'text1',
    width: '42',
    height: '42',
    cursor: 'pointer',
    transitionDuration: '125',
  }),
])

export const navLinksContainer = sprinkles({
  gap: '12',
  display: {
    sm: 'none',
    md: 'flex',
  },
})

export const navLink = sprinkles({
  fontWeight: 'medium',
  fontSize: '18',
  paddingX: '12',
  paddingY: '8',
  borderRadius: '10',
  opacity: {
    hover: '0.7',
  },
})
