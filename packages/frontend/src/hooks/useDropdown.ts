import { useCallback, useEffect, useRef, useState } from 'react'

export function useDropdown() {
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

  return { dropdownRef, dropdownOpened, toggleDropdown }
}
