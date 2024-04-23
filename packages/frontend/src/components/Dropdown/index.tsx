import { useCallback, useEffect, useRef, useState } from 'react'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'

import { IconButton } from '../Button'
import * as styles from './style.css'

const Dropdown = ({ children }: any) => {
  const dropdownRef = useRef<HTMLDivElement>(null)
  const [dropdownOpened, setDropdownOpened] = useState(false)
  const toggleDropdown = useCallback(() => setDropdownOpened((state) => !state), [])

  const handleClickOutside = (e: MouseEvent) => {
    if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
      setDropdownOpened(false)
    }
  }

  useEffect(() => {
    if (dropdownOpened) {
      document.addEventListener('mousedown', handleClickOutside)
      return () => {
        document.removeEventListener('mousedown', handleClickOutside)
      }
    }
    return
  }, [dropdownRef, dropdownOpened])

  return (
    <Box position="relative" ref={dropdownRef}>
      <IconButton onClick={toggleDropdown} large>
        <Icons.ThreeDots display="block" width="16" />
      </IconButton>
      {dropdownOpened && <Column className={styles.dropdown()}>{children}</Column>}
    </Box>
  )
}

export default Dropdown
