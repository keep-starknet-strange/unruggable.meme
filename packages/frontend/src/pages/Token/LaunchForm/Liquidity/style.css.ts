import { recipe } from '@vanilla-extract/recipes'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const errorContainer = sprinkles({
  paddingX: '8',
  paddingTop: '4',
  color: 'error',
})

export const quoteTokenCard = recipe({
  base: {
    flex: '1',
    minWidth: '150px',
  },
  variants: {
    selected: {
      true: sprinkles({
        background: 'gray700',
      }),
    },
  },
})
