import { Link, useNavigate } from 'react-router-dom'
import Box from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'
import * as Text from 'src/theme/components/Text'

import Web3Status from '../Web3Status'
import * as styles from './style.css'

export const links = [
  {
    name: 'Launch',
    path: '/launch',
  },
  {
    name: 'Manage',
    path: '/manage',
  },
]

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

          <Box className={styles.navLinksContainer}>
            {links.map(({ name, path }) => (
              <Link key={path} to={path}>
                <Text.Body className={styles.navLink}>{name}</Text.Body>
              </Link>
            ))}
          </Box>
        </Row>

        <Box>
          <Web3Status />
        </Box>
      </Row>
    </Box>
  )
}
