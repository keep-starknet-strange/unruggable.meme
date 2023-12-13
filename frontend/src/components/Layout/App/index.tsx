import NavBar from 'src/components/NavBar'
import NavBarMobile from 'src/components/NavBar/Mobile'
import Box from 'src/theme/components/Box'

import * as styles from './style.css'

interface AppLayoutProps {
  children: React.ReactNode
}

export default function AppLayout({ children }: AppLayoutProps) {
  return (
    <>
      <NavBar />
      <NavBarMobile />
      <Box as="span" className={styles.radial} />
      {children}
    </>
  )
}
