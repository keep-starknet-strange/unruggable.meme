import { style } from '@vanilla-extract/css'
import { recipe } from '@vanilla-extract/recipes'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const navBarContainer = style([
  {
    borderTopLeftRadius: '16px',
    borderTopRightRadius: '16px',
  },
  sprinkles({
    background: 'bg2',
    position: 'fixed',
    bottom: '0',
    left: '0',
    right: '0',
    paddingX: '8',
    paddingBottom: '18',
    paddingTop: '16',
    borderColor: 'border1',
    borderTopWidth: '1px',
    borderStyle: 'solid',
    display: {
      md: 'none',
    },
  }),
])

export const navLink = recipe({
  base: [
    sprinkles({
      paddingX: '12',
      paddingY: '8',
      borderRadius: '10',
    }),
  ],

  variants: {
    active: {
      true: sprinkles({ background: 'bg3' }),
      false: {},
    },
  },

  defaultVariants: {
    active: false,
  },
})
