import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Box from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'
import * as Text from 'src/theme/components/Text'

import Web3Status from '../Web3Status'
import * as styles from './style.css'

export const links = [
  {
    name: 'Deploy',
    path: '/deploy',
  },
  {
    name: 'My tokens',
    path: '/tokens',
  },
]

export default function NavBar() {
  // state
  const [scrolledOnTop, setScrolledOnTop] = useState(true)

  const navigate = useNavigate()

  useEffect(() => {
    const scrollListener = () => {
      setScrolledOnTop(!window.scrollY)
    }

    window.addEventListener('scroll', scrollListener)

    return () => window.removeEventListener('scroll', scrollListener)
  }, [])

  return (
    <Box as="nav" className={styles.nav({ onTop: scrolledOnTop })}>
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
