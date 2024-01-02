import { useAccount } from '@starknet-react/core'
import { useL2WalletOverviewModal, useWalletConnectModal } from 'src/hooks/useModal'
import Box from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'
import { shortenL2Address } from 'src/utils/address'

import { PrimaryButton, SecondaryButton } from '../Button'
import WalletConnectModal from '../WalletModal/Connect'
import { L2WalletOverviewModal } from '../WalletModal/Overview'
import * as styles from './styles.css'

function Web3StatusContent() {
  const { address: l2Account } = useAccount()

  // modal
  const [, toggleWalletConnectModal] = useWalletConnectModal()
  const [, toggleL2WalletOverviewModal] = useL2WalletOverviewModal()

  if (l2Account) {
    return (
      <Row gap="8">
        <SecondaryButton onClick={toggleL2WalletOverviewModal} withIcon>
          <Row gap="8">
            <Box className={styles.iconContainer}>
              <Icons.Starknet />
            </Box>
            {shortenL2Address(l2Account)}
          </Row>
        </SecondaryButton>
      </Row>
    )
  } else {
    return (
      <PrimaryButton onClick={toggleWalletConnectModal} minWidth="180">
        Connect wallet
      </PrimaryButton>
    )
  }
}

export default function Web3Status() {
  return (
    <>
      <Web3StatusContent />

      <WalletConnectModal />
      <L2WalletOverviewModal />
    </>
  )
}
