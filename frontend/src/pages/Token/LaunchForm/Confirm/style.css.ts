import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const AMMNavigatior = style([
  {
    borderRadius: '4px',
  },
  sprinkles({
    transition: '125',
    alignSelf: 'stretch',
    justifyContent: 'center',
    alignItems: 'center',
    width: '24',
    cursor: 'pointer',
    background: {
      default: 'bg2',
      hover: 'text2',
    },
    color: {
      default: 'text2',
      hover: 'text1',
    },
  }),
])
