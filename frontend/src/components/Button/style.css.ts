import { style } from '@vanilla-extract/css'
import { recipe } from '@vanilla-extract/recipes'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const Base = sprinkles({
  borderRadius: '10',
  fontWeight: 'medium',
  cursor: 'pointer',
  fontSize: '16',
  color: 'text1',
  paddingY: '12',
})

export const primaryButton = style([
  Base,
  sprinkles({
    paddingX: '16',
    border: 'none',
    background: {
      default: 'vibrantGradient',
      hover: 'accentDark',
      focus: 'accentDarker',
      active: 'accentDarker',
    },
    outlineStyle: 'solid',
    outlineWidth: '1px',
    outlineColor: {
      default: 'transparent',
      hover: 'accentDark',
      focus: 'accentDarker',
      active: 'accentDarker',
    },
    color: 'text1',
  }),
])

export const secondaryButton = recipe({
  base: [
    Base,
    sprinkles({
      paddingRight: '16',
      background: 'transparent',
      borderWidth: '1px',
      borderStyle: 'solid',
      borderColor: {
        default: 'text2',
        hover: 'text1',
      },
      color: {
        default: 'text2',
        hover: 'text1',
      },
      transitionDuration: 'fast',
    }),
  ],

  variants: {
    withIcon: {
      true: sprinkles({ paddingLeft: '8' }),
      false: sprinkles({ paddingLeft: '16' }),
    },
  },

  defaultVariants: {
    withIcon: false,
  },
})
