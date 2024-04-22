import { NavLink } from 'react-router-dom'
import Box from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import { links } from '..'
import * as styles from './style.css'

export default function NavBarMobile() {
  return (
    <Box className={styles.navBarContainer}>
      <Row justifyContent="space-around">
        {links.map(({ name, path }) => (
          <NavLink key={path} to={path} className={({ isActive }) => styles.navLink({ active: isActive })}>
            <Text.Body>{name}</Text.Body>
          </NavLink>
        ))}
      </Row>
    </Box>
  )
}
