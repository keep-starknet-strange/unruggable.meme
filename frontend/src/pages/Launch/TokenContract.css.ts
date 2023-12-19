import { style } from '@vanilla-extract/css'
import { recipe } from '@vanilla-extract/recipes'
import { transparentize } from 'polished'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

export const tokenContractContainer = style([
  {
    backgroundImage: `
      linear-gradient(to top, ${transparentize(0.6, '#12181c')} 0%, ${transparentize(0.5, '#12181c')} 70%),
      url("src/assets/forest.png")
    `,
    backgroundSize: '150%',
    backgroundRepeat: 'no-repeat',
    boxShadow: '0 10px 16px #00000040',

    ':hover': {
      boxShadow: '0 12px 16px #00000080',
      filter: 'brightness(1.1)',
    },
  },
  sprinkles({
    width: 'full',
    borderRadius: '10',
    paddingY: '16',
    paddingX: '12',
    cursor: 'pointer',
    transitionDuration: '125',
  }),
])

export const teamAllocation = style([
  sprinkles({
    fontSize: '18',
    color: 'text1',
    fontWeight: 'bold',
  }),
])

export const launchStatus = recipe({
  base: [
    {
      borderRadius: '6px',
      boxShadow: '0 0 4px #00000080',

      '::before': {
        content: '""',
        width: '12px',
        height: '12px',
        display: 'block',
        borderRadius: '6px',
      },
    },
    sprinkles({
      display: 'flex',
      alignItems: 'center',
      gap: '8',
      background: 'bg3',
      paddingX: '8',
      paddingY: '4',
      color: 'text1',
      fontWeight: 'semibold',
    }),
  ],

  variants: {
    launched: {
      true: {
        '::before': {
          background: vars.color.accent,
        },
      },
      false: {
        '::before': {
          background: vars.color.text2,
        },
      },
    },
  },

  defaultVariants: {
    launched: false,
  },
})
