import { useNetwork } from '@starknet-react/core'
import NavBar from 'src/components/NavBar'
import NavBarMobile from 'src/components/NavBar/Mobile'
import { TransactionModal } from 'src/components/TransactionModal'
import useChainId from 'src/hooks/useChainId'
import Box from 'src/theme/components/Box'
import { constants } from 'starknet'

import * as styles from './style.css'

export default function AppLayout({ children }: React.PropsWithChildren) {
  const { chain } = useNetwork()
  const chaindId = useChainId()

  return (
    <>
      {chaindId !== constants.StarknetChainId.SN_MAIN && (
        <Box className={styles.chainWarning}>{chain.name} network.</Box>
      )}
      <NavBar />
      <NavBarMobile />
      <Box as="span" className={styles.radial} />

      {children}

      <TransactionModal />
    </>
  )
}
