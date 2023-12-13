import { style } from '@vanilla-extract/css'
import { transparentize } from 'polished'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

export const container = style([
  {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    textAlign: 'center',
    overflow: 'auto',
  },
])

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
  paddingX: '32',
})

export const title = style([
  {
    textShadow: '4px 4px 0 #000000',
    color: 'white',
  },
  sprinkles({
    marginTop: '42',
    marginBottom: '0',
    fontSize: { md: '48', lg: '96' },
  }),
])

export const subtitle = style([
  sprinkles({
    maxHeight: { sm: '18', md: '32', lg: '32' },
    marginX: 'auto',
  }),
])

export const firstArticle = style([
  sprinkles({
    marginTop: '42',
    gap: '24',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontWeight: 'normal',
    paddingX: { sm: '32', md: '64' },
    fontSize: { sm: '18', md: '24', lg: '24' },
    color: 'white',
  }),
])

export const firstArticleButton = style([
  sprinkles({
    width: '180',
  }),
])

export const buttonContainer = style([
  {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    textAlign: 'center',
    flexWrap: 'wrap',
  },
])
