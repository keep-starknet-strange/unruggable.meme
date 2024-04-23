import { recipe } from '@vanilla-extract/recipes'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

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
})
