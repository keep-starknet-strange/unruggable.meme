import { Link, useNavigate } from 'react-router-dom'
import Box from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'
import * as Text from 'src/theme/components/Text'

import Web3Status from '../Web3Status'
import * as styles from './style.css'

export default function NavBar() {
  const navigate = useNavigate()

  return (
    <Box as="nav" className={styles.nav}>
      <Row justifyContent="space-between">
        <Row gap="24">
          <Box className={styles.logoContainer}>
            <Icons.Logo
              onClick={() => {
                navigate({ pathname: '/' })
              }}
            />
          </Box>

          <Row gap="12">
            <Link to="/launch">
              <Text.Body className={styles.navLink}>Launch</Text.Body>
            </Link>

            <Link to="/manage">
              <Text.Body className={styles.navLink}>Manage</Text.Body>
            </Link>
          </Row>
        </Row>

        <Box>
          <Web3Status />
        </Box>
      </Row>
    </Box>
  )
}
