import { useAccount } from '@starknet-react/core'
import { useEffect } from 'react'
import { getL2Connections } from 'src/connections'
import { useWalletConnectModal } from 'src/hooks/useModal'
import { Column } from 'src/theme/components/Flex'

import Portal from '../common/Portal'
import Content from '../Modal/Content'
import Overlay from '../Modal/Overlay'
import { L2Option } from './Option'

function WalletConnectContent() {
  // accounts
  const { address: l2Account } = useAccount()

  // connections
  const l2Connections = getL2Connections()

  // modal
  const [, toggle] = useWalletConnectModal()

  // close modal if both layers have a connected wallet
  useEffect(() => {
    if (l2Account) {
      toggle()
    }
  }, [toggle, l2Account])

  return (
    <Content title="Connect Starknet wallet" close={toggle}>
      <Column gap="8">
        {l2Connections
          .filter((connection) => connection.shouldDisplay())
          .map((connection) => (
            <L2Option key={connection.getName()} connection={connection} />
          ))}
      </Column>
    </Content>
  )
}

export default function WalletConnectModal() {
  // modal
  const [isOpen, toggle] = useWalletConnectModal()

  if (!isOpen) return null

  return (
    <Portal>
      <WalletConnectContent />

      <Overlay onClick={toggle} />
    </Portal>
  )
}
