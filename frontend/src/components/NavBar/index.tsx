import { useNavigate } from 'react-router-dom'
import Box from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'

import Web3Status from '../Web3Status'
import * as styles from './style.css'

export default function NavBar() {
  const navigate = useNavigate()

  return (
    <Box as="nav" className={styles.Nav}>
      <Row justifyContent="space-between">
        <Box className={styles.leftSideContainer}>
          <Box className={styles.logoContainer}>
            <Icons.Logo
              onClick={() => {
                navigate({ pathname: '/' })
              }}
            />
          </Box>
        </Box>

        <Box className={styles.rightSideContainer}>
          <Web3Status />
        </Box>
      </Row>
    </Box>
  )
}
