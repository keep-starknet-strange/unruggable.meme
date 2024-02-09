import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const ammContainer = style([
  sprinkles({
    gap: {
      sm: '24',
      md: '32',
    },
    padding: {
      sm: '0',
      md: '12',
    },
  }),
])

export const ammNavigatior = style([
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

export const separator = sprinkles({
  width: 'full',
  height: '2',
  background: 'bg2',
})

export const amountRowContainer = sprinkles({
  gap: '12',
  justifyContent: 'space-between',
})

export const amountContainer = style([
  {
    gap: '4px 8px',
  },
  sprinkles({
    flexWrap: 'wrap-reverse',
    justifyContent: 'flex-end',
  }),
])
