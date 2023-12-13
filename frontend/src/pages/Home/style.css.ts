import { style } from '@vanilla-extract/css'
import { transparentize } from 'polished'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

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

export const titleContainer = sprinkles({
  textAlign: 'center',
  gap: '16',
})

export const title = style([
  {
    fontSize: '96px',
    textShadow: '4px 4px 0 #000000',
  },
  sprinkles({
    marginTop: '42',
  }),
])

export const subtitle = style([
  sprinkles({
    maxHeight: '64',
    marginX: 'auto',
  }),
])

export const firstArticle = style([
  sprinkles({
    marginTop: '128',
    gap: '24',
    alignItems: 'center',
  }),
])

export const firstArticleButton = style([
  sprinkles({
    width: '180',
  }),
])

export const secondArticle = style([
  sprinkles({
    position: 'absolute',
    left: '64',
    bottom: '64',
    right: '64',
    borderColor: 'border1',
    borderStyle: 'solid',
    borderWidth: '0px',
    borderTopWidth: '1px',
    paddingTop: '24',
    paddingX: '32',
  }),
])
