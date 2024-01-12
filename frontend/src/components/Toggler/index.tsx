import { Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './style.css'

interface TogglerProps {
  modes: string[]
  index: number
  setIndex: (value: number) => void
}

export default function Toggler({ modes, index: selectedIndex, setIndex }: TogglerProps) {
  return (
    <Row className={styles.container}>
      {modes.map((mode, index) => (
        <Text.Custom
          key={mode}
          className={styles.togglerButton({ active: selectedIndex === index })}
          onClick={() => setIndex(index)}
        >
          {mode}
        </Text.Custom>
      ))}
    </Row>
  )
}
