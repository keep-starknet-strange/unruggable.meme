import { style } from '@vanilla-extract/css'
import { recipe } from '@vanilla-extract/recipes'
import { breakpoints, sprinkles } from 'src/theme/css/sprinkles.css'

export const slotsContainer = style([
  {
    gridTemplateColumns: 'repeat(2, 1fr)',
    '@media': {
      [`screen and (min-width: ${breakpoints.md}px)`]: {
        gridTemplateColumns: 'repeat(5, 1fr)',
      },
    },
  },
  sprinkles({
    display: 'grid',
    gap: '16',
  }),
])

export const slot = recipe({
  base: sprinkles({
    background: 'bg2',
    borderColor: {
      default: 'border2',
      hover: 'text1',
    },
    borderWidth: '1px',
    borderStyle: 'solid',
    width: 'full',
    height: '64',
    borderRadius: '10',
    cursor: 'pointer',
    justifyContent: 'center',
    alignItems: 'center',
    color: {
      default: 'text2',
      hover: 'text1',
    },
  }),
  variants: {
    empty: {
      true: sprinkles({
        opacity: '0.5',
      }),
    },
  },
})
