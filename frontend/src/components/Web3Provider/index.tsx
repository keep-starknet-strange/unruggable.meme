import { sepolia } from '@starknet-react/chains'
import { publicProvider, StarknetConfig, starkscan } from '@starknet-react/core'
import { ArgentMobileConnector } from 'starknetkit/argentMobile'
import { InjectedConnector } from 'starknetkit/injected'
import { WebWalletConnector } from 'starknetkit/webwallet'

// STARKNET

interface StarknetProviderProps {
  children: React.ReactNode
}

export function StarknetProvider({ children }: StarknetProviderProps) {
  const connectors = [
    new InjectedConnector({ options: { id: 'argentX', name: 'Argent' } }),
    new InjectedConnector({ options: { id: 'braavos', name: 'Braavos' } }),
    new WebWalletConnector({ url: 'https://web.argent.xyz' }),
    new ArgentMobileConnector(),
  ]

  return (
    <StarknetConfig
      connectors={connectors}
      chains={[sepolia]}
      provider={publicProvider()}
      explorer={starkscan}
      autoConnect
    >
      {children}
    </StarknetConfig>
  )
}
