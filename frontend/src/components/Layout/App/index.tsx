import { useAccount, useNetwork } from '@starknet-react/core'
import NavBar from 'src/components/NavBar'
import NavBarMobile from 'src/components/NavBar/Mobile'
import { TransactionModal } from 'src/components/TransactionModal'
import Box from 'src/theme/components/Box'

import * as styles from './style.css'

interface AppLayoutProps {
  children: React.ReactNode
}

export default function AppLayout({ children }: AppLayoutProps) {
  const { chainId: walletChainId } = useAccount()
  const { chain } = useNetwork()

  return (
    <>
      {walletChainId !== undefined && walletChainId !== chain.id && (
        <Box className={styles.chainWarning}>
          The selected wallet is connected to the wrong network. Please switch to the {chain.name} network.
        </Box>
      )}
      <NavBar />
      <NavBarMobile />
      <Box as="span" className={styles.radial} />

      {children}

      <TransactionModal />
    </>
  )
}
