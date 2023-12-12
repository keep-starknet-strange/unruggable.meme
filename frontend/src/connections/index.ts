import { InjectedConnector } from '@starknet-react/core'
import ARGENT_X_ICON from 'src/assets/argent-x.svg'
import BRAAVOS_ICON from 'src/assets/braavos.svg'
import { isMobile } from 'src/utils/userAgent'

import { getShouldAdvertiseArgentX, getShouldAdvertiseBraavos } from './utils'

enum ConnectionType {
  ARGENT_X = 'ARGENT_X',
  BRAAVOS = 'BRAAVOS',
}

export interface L2Connection {
  getName(): string
  connector: InjectedConnector
  type: ConnectionType
  getIcon?(): string
  shouldDisplay(): boolean
  overrideActivate?: () => boolean
}

export type Connection = L2Connection

// ARGENT X

const starknetArgentXWallet = new InjectedConnector({ options: { id: 'argentX' } })

const argentXWalletConnection: L2Connection = {
  getName: () => 'Argent X',
  connector: starknetArgentXWallet,
  type: ConnectionType.ARGENT_X,
  getIcon: () => ARGENT_X_ICON,
  shouldDisplay: () => Boolean(!isMobile),
  // If on non-injected, non-mobile browser, prompt user to install ArgentX
  overrideActivate: () => {
    if (getShouldAdvertiseArgentX()) {
      window.open('https://www.argent.xyz/argent-x/', 'inst_argent')
      return true
    }
    return false
  },
}

// BRAAVOS

const starknetBraavosWallet = new InjectedConnector({ options: { id: 'braavos' } })

const braavosWalletConnection: L2Connection = {
  getName: () => 'Braavos',
  connector: starknetBraavosWallet,
  type: ConnectionType.BRAAVOS,
  getIcon: () => BRAAVOS_ICON,
  shouldDisplay: () => true,
  // If on non-injected, prompt user to install Braavos
  overrideActivate: () => {
    if (getShouldAdvertiseBraavos()) {
      window.open('https://braavos.app/', 'inst_braavos')
      return true
    }
    return false
  },
}

// GETTERS

export function getL2Connections() {
  return [argentXWalletConnection, braavosWalletConnection]
}
