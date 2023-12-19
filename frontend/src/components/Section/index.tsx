import clsx from 'clsx'
import { BoxProps } from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'

import * as styles from './style.css'

export default function Section({ className, children, ...props }: BoxProps) {
  return (
    <Row className={clsx(className, styles.wrapper)} {...props}>
      {children}
    </Row>
  )
}
