import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'

export const content = style([
  sprinkles({
    borderWidth: '1px',
    borderStyle: 'solid',
    borderColor: 'border1',
    borderRadius: '10',
    padding: '24',
    background: 'bg1',
    zIndex: 'modal',
    position: 'fixed',
    left: '1/2',
    top: '1/2',
    width: '480',
  }),
  {
    transform: 'translate(-50%, -50%)',
  },
])

export const closeContainer = sprinkles({
  color: 'text1',
  width: '24',
  height: '24',
  cursor: 'pointer',
})
