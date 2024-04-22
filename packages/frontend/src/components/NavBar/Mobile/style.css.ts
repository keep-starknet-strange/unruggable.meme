import { style } from '@vanilla-extract/css'
import { recipe } from '@vanilla-extract/recipes'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

export const navBarContainer = style([
  {
    borderTopLeftRadius: '16px',
    borderTopRightRadius: '16px',
    boxShadow: `0 0 0 1px ${vars.color.border1}`,
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
    display: {
      md: 'none',
    },
    zIndex: 'sticky',
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
      true: sprinkles({ background: 'text2' }),
      false: {},
    },
  },

  defaultVariants: {
    active: false,
  },
})
