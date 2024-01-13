import { recipe } from '@vanilla-extract/recipes'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const container = sprinkles({
  borderWidth: '1px',
  borderColor: 'border2',
  borderStyle: 'solid',
  borderRadius: '10',
  paddingY: '1',
  paddingX: '1',
  background: 'bg2',
})

export const togglerButton = recipe({
  base: [
    {
      borderRadius: '8px',
    },
    sprinkles({
      cursor: 'pointer',
      fontWeight: 'medium',
      fontSize: '16',
      paddingY: '6',
      paddingX: '8',
    }),
  ],

  variants: {
    active: {
      true: sprinkles({
        background: 'bg1',
        color: 'text1',
      }),
      false: sprinkles({
        color: 'text2',
      }),
    },
  },

  defaultVariants: {
    active: false,
  },
})
