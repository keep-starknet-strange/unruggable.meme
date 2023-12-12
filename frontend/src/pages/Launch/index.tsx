import { PrimaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './style.css'

export default function HomePage() {
  return (
    <Row className={styles.wrapper}>
      <Box className={styles.container}>
        <Box as="form">
          <Column gap="20">
            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Name</Text.Body>
              <Input placeholder="Dogecoin" />
            </Column>

            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Symbol</Text.Body>
              <Input placeholder="DOGE" />
            </Column>

            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Decimals</Text.Body>
              <Input placeholder="18" />
            </Column>

            <div />

            <PrimaryButton className={styles.deployButton}>DEPLOY</PrimaryButton>
          </Column>
        </Box>
      </Box>
    </Row>
  )
}
