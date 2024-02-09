import { style } from '@vanilla-extract/css'
import { recipe } from '@vanilla-extract/recipes'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

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

export const primaryButton = recipe({
  base: [
    Base,
    sprinkles({
      paddingX: '16',
      border: 'none',
      background: 'accent',
      color: 'text1',
      position: 'relative',
      outlineColor: 'accent',
      outlineStyle: 'solid',
      outlineWidth: {
        default: '0px',
        hover: '1px',
        active: '1px',
      },
    }),
  ],

  variants: {
    large: {
      true: sprinkles({
        minHeight: '54',
        fontSize: '18',
        fontWeight: 'medium',
      }),
    },
    disabled: {
      true: [
        {
          background: `${vars.color.bg2} !important`,
          outline: 'none !important',
          cursor: 'default !important',
        },
        sprinkles({ opacity: '0.5' }),
      ],
    },
  },

  defaultVariants: {
    large: false,
    disabled: false,
  },
})

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
    large: {
      true: sprinkles({
        minHeight: '54',
        fontSize: '18',
        fontWeight: 'medium',
      }),
    },
    withIcon: {
      true: sprinkles({ paddingLeft: '8' }),
      false: sprinkles({ paddingLeft: '16' }),
    },
  },

  defaultVariants: {
    withIcon: false,
    large: false,
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
