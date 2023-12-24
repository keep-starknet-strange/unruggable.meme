import { style } from '@vanilla-extract/css'
import { recipe } from '@vanilla-extract/recipes'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const Base = style([
  {
    selectors: {
      '&:disabled': {
        opacity: 0.5,
        cursor: 'default',
      },
    },
  },
  sprinkles({
    borderRadius: '10',
    fontWeight: 'medium',
    cursor: 'pointer',
    fontSize: '16',
    color: 'text1',
    paddingY: '12',
    pointerEvents: {
      default: 'all',
      disabled: 'none',
    },
  }),
])

export const primaryButton = style([
  Base,
  sprinkles({
    paddingX: '16',
    border: 'none',
    background: 'accentGradient',
    opacity: {
      hover: 'hover',
      focus: 'focus',
      active: 'focus',
    },
    color: 'text1',
    position: 'relative',
  }),
])

export const primaryButtonSpan = style([
  {
    selectors: {
      [`${primaryButton}:hover &`]: {
        opacity: 1,
      },
    },
  },
  sprinkles({
    background: 'accent',
    transition: '125',
    position: 'absolute',
    opacity: '0',
    top: '0',
    right: '0',
    bottom: '0',
    left: '0',
    borderRadius: '10',
  }),
])

export const secondaryButton = recipe({
  base: [
    Base,
    sprinkles({
      paddingRight: '16',
      background: {
        default: 'transparent',
        hover: 'text1',
      },
      borderWidth: '1px',
      borderStyle: 'solid',
      borderColor: 'text1',
      color: {
        default: 'text1',
        hover: 'bg1',
      },
      transitionDuration: '125',
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

export const iconButton = style([
  sprinkles({
    paddingX: '2',
    paddingY: '2',
    fontSize: '14',
    borderRadius: '10',
    fontWeight: 'medium',
    cursor: 'pointer',
    pointerEvents: {
      default: 'all',
      disabled: 'none',
    },
    color: {
      default: 'text2',
      hover: 'text1',
    },
    background: 'transparent',
    border: 'none',
  }),
])

export const thirdDimension = style([
  primaryButton,
  {
    overflow: 'hidden',
    boxShadow: '0 6px 10px #00000040',
    position: 'relative',

    '::before': {
      content: '""',
      position: 'absolute',
      zIndex: 1,
      top: '2px',
      left: '6px',
      right: '6px',
      height: '12px',
      borderRadius: '20px 20px 100px 100px / 14px 14px 30px 30px',
      background: 'linear-gradient(rgba(255, 255, 255, 0.2), rgba(255, 255, 255, 0))',
    },
  },
])
