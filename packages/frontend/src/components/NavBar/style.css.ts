import { style } from '@vanilla-extract/css'
import { recipe } from '@vanilla-extract/recipes'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const nav = recipe({
  base: [
    sprinkles({
      position: 'sticky',
      top: '0',
      paddingX: '24',
      paddingY: {
        sm: '16',
        md: '24',
      },
      zIndex: 'sticky',
      transition: '125',
    }),
  ],

  variants: {
    onTop: {
      true: {},
      false: [
        sprinkles({
          background: 'bg1',
          borderWidth: '0px',
          borderBottomWidth: '1px',
          borderColor: 'border1',
          borderStyle: 'solid',
        }),
      ],
    },
  },

  defaultVariants: {
    onTop: true,
  },
})

export const logoContainer = style([
  {
    ':hover': {
      transform: 'rotate(5deg)',
    },
  },
  sprinkles({
    color: 'text1',
    width: '42',
    height: '42',
    cursor: 'pointer',
    transitionDuration: '125',
  }),
])

export const navLinksContainer = sprinkles({
  gap: '12',
  display: {
    sm: 'none',
    md: 'flex',
  },
})

export const navLink = sprinkles({
  fontWeight: 'medium',
  fontSize: '18',
  paddingX: '12',
  paddingY: '8',
  borderRadius: '10',
  opacity: {
    hover: '0.7',
  },
})
