import { style } from '@vanilla-extract/css'
import { breakpoints, sprinkles } from 'src/theme/css/sprinkles.css'

export const content = style([
  {
    '@media': {
      [`(min-width: ${breakpoints.sm}px)`]: {
        padding: '32px',
        top: '50%',
        left: '50%',
        width: '480px',
        transform: 'translate(-50%, -50%)',
        bottom: 'unset',
      },
    },
  },
  sprinkles({
    borderWidth: '1px',
    borderStyle: 'solid',
    borderColor: 'border1',
    borderRadius: '10',
    background: 'bg1',
    zIndex: 'modal',
    position: 'fixed',
    bottom: '0',
    top: '0',
    paddingX: '32',
    paddingY: '88',
    width: 'full',
  }),
])

export const title = sprinkles({
  fontSize: {
    sm: '32',
    md: '24',
  },
})

export const closeContainer = sprinkles({
  color: 'text1',
  width: '24',
  height: '24',
  cursor: 'pointer',
})
