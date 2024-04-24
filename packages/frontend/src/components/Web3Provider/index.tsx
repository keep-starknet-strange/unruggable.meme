import { argent, braavos, StarknetConfig, starkscan, useInjectedConnectors, useNetwork } from '@starknet-react/core'
import { Provider as HooksProvider } from 'hooks'
import { useMemo } from 'react'
import { nethermindRpcProviders, SUPPORTED_STARKNET_NETWORKS } from 'src/constants/networks'
import { ArgentMobileConnector } from 'starknetkit/argentMobile'
import { WebWalletConnector } from 'starknetkit/webwallet'

// STARKNET

export function StarknetProvider({ children }: React.PropsWithChildren) {
  const { connectors: injected } = useInjectedConnectors({
    recommended: [argent(), braavos()],
    includeRecommended: 'always',
  })

  const connectors = [
    ...injected,
    new WebWalletConnector({ url: 'https://web.argent.xyz' }),
    new ArgentMobileConnector(),
  ]

  return (
    <StarknetConfig
      connectors={connectors}
      chains={SUPPORTED_STARKNET_NETWORKS}
      provider={nethermindRpcProviders}
      explorer={starkscan}
      autoConnect
    >
      {children}
    </StarknetConfig>
  )
}

// SDK HOOKS
interface HooksSDKProviderProps {
  children: React.ReactNode
}

export function HooksSDKProvider({ children }: HooksSDKProviderProps) {
  const { chain } = useNetwork()

  const provider = useMemo(() => nethermindRpcProviders(chain) ?? undefined, [chain])

  return <HooksProvider provider={provider}>{children}</HooksProvider>
}
