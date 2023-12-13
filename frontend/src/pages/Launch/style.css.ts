import { style } from '@vanilla-extract/css'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'
import { transparentize } from 'polished'

export const backgroundContainer = style([
  {
    zIndex: '-99',
    position: 'absolute',
    top: '0',
    right: '0',
    bottom: '0',
    left: '0',
    height: '100vh',
    maxHeight: '1000px',
  },
])

export const background = style([
  {
    backgroundImage: `
      linear-gradient(to bottom, ${transparentize(0.3, '#000000')}, ${vars.color.bg1}),
      url("src/assets/background.png")
    `,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
    backgroundRepeat: 'no-repeat',
  },
  sprinkles({
    position: 'absolute',
    top: '0',
    right: '0',
    bottom: '0',
    left: '0',
    width: 'full',
    height: 'full',
  }),
])

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
