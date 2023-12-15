import { useDisconnect, useNetwork } from '@starknet-react/core'
import { useCallback } from 'react'
import { useCloseModal, useL2WalletOverviewModal } from 'src/hooks/useModal'

import { SecondaryButton } from '../Button'
import Portal from '../common/Portal'
import Content from '../Modal/Content'
import Overlay from '../Modal/Overlay'

interface WalletOverviewModalProps {
  chainLabel?: string
  disconnect: () => void
}

function WalletOverviewModal({ chainLabel, disconnect }: WalletOverviewModalProps) {
  // modal
  const close = useCloseModal()

  // disconnect
  const disconnectAndClose = useCallback(() => {
    disconnect()
    close()
  }, [disconnect, close])

  return (
    <Portal>
      <Content title={`${chainLabel} wallet`} close={close}>
        <SecondaryButton onClick={disconnectAndClose}>Disconnect</SecondaryButton>
      </Content>

      <Overlay onClick={close} />
    </Portal>
  )
}

export function L2WalletOverviewModal() {
  // modal
  const [isOpen] = useL2WalletOverviewModal()

  // disconnect
  const { disconnect } = useDisconnect()

  // chain infos
  const { chain } = useNetwork()

  if (!isOpen) return null

  return <WalletOverviewModal chainLabel={chain?.name} disconnect={disconnect} />
}
