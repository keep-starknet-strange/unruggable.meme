import { recipe } from '@vanilla-extract/recipes'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const iconContainer = recipe({
  base: sprinkles({
    padding: '16',
    borderRadius: 'round',
    color: 'text1',
  }),

  variants: {
    success: {
      true: sprinkles({
        background: 'accent',
      }),
      false: sprinkles({
        background: 'error',
      }),
    },
  },
})
