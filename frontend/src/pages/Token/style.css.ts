import { style } from '@vanilla-extract/css'
import { recipe } from '@vanilla-extract/recipes'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

export const container = style([
  {
    padding: '16px 12px 12px',
    boxShadow: `0 0 16px ${vars.color.bg1}`,
  },
  sprinkles({
    maxWidth: '620',
    width: 'full',
    background: 'bg1',
    borderRadius: '10',
    border: 'light',
    gap: '32',
  }),
])

export const hr = style([
  {
    height: '1px',
  },
  sprinkles({
    width: 'full',
    background: 'border1',
  }),
])

export const card = style([
  {
    flex: '1',
    minWidth: '208px',
  },
  sprinkles({
    borderRadius: '10',
    backgroundColor: 'bg2',
    paddingX: '24',
    paddingY: '16',
    borderColor: 'border2',
    borderWidth: '1px',
    borderStyle: 'solid',
  }),
])

export const errorContainer = sprinkles({
  paddingX: '8',
  paddingTop: '4',
  color: 'error',
})

export const dropdown = recipe({
  base: [
    {
      boxShadow: `0 0 8px ${vars.color.bg1}`,
    },
    sprinkles({
      position: 'absolute',
      background: 'bg2',
      right: '0',
      marginTop: '8',
      borderRadius: '10',
      overflow: 'hidden',
      minWidth: '180',
    }),
  ],

  variants: {
    opened: {
      false: {
        display: 'none',
      },
    },
  },

  defaultVariants: {
    opened: false,
  },
})

export const dropdownRow = style([
  sprinkles({
    paddingX: '16',
    paddingY: '12',
    background: {
      default: 'transparent',
      hover: 'border2',
    },
  }),
])
