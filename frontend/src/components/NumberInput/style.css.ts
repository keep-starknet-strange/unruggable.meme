import { sprinkles } from 'src/theme/css/sprinkles.css'

export const inputContainer = sprinkles({
  display: 'flex',
  alignItems: 'center',
  borderRadius: '10',
  borderWidth: '1px',
  borderStyle: 'solid',
  overflow: 'hidden',
  padding: '12',
  fontSize: '16',
  borderColor: {
    default: 'border1',
    hover: 'accent',
  },
  gap: '8',
  transitionDuration: '125',
  backgroundColor: 'bg1',
})

export const input = sprinkles({
  fontSize: '16',
  position: 'relative',
  whiteSpace: 'nowrap',
  outline: 'none',
  color: {
    default: 'text1',
    placeholder: 'text2',
  },
  background: 'none',
  border: 'none',
  width: 'full',
})
