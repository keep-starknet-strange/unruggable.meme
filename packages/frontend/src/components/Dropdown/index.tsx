import { useCallback, useRef, useState } from 'react'
import { useOnClickOutside } from 'src/hooks/useClickOutside'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'

import { IconButton } from '../Button'
import * as styles from './style.css'

const Dropdown = ({ children }: React.PropsWithChildren) => {
  const [isOpen, setIsOpen] = useState(false)

  // dropdown state
  const toggleDropdown = useCallback(() => setIsOpen((state) => !state), [])
  const dropdownRef = useRef<HTMLDivElement>(null)

  useOnClickOutside(dropdownRef, isOpen ? toggleDropdown : undefined)

  return (
    <Box position="relative" ref={dropdownRef}>
      <IconButton onClick={toggleDropdown} large>
        <Icons.ThreeDots display="block" width="16" />
      </IconButton>

      {isOpen && <Column className={styles.dropdown()}>{children}</Column>}
    </Box>
  )
}

export default Dropdown
