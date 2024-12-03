import {
  argent,
  braavos,
  Connector,
  StarknetConfig,
  starkscan,
  useInjectedConnectors,
  useNetwork,
} from '@starknet-react/core'
import { QueryClient } from '@tanstack/react-query'
import { Provider as HooksProvider } from 'hooks'
import { useMemo } from 'react'
import { nethermindRpcProviders, SUPPORTED_STARKNET_NETWORKS } from 'src/constants/networks'
import { ArgentMobileConnector } from 'starknetkit/argentMobile'
import { WebWalletConnector } from 'starknetkit/webwallet'

// Query Client

const queryClient = new QueryClient()

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
  ] as Connector[]

  return (
    <StarknetConfig
      queryClient={queryClient}
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
export function HooksSDKProvider({ children }: React.PropsWithChildren) {
  const { chain } = useNetwork()

  const provider = useMemo(() => nethermindRpcProviders(chain) ?? undefined, [chain])

  return (
    <HooksProvider provider={provider} queryClient={queryClient}>
      {children}
    </HooksProvider>
  )
}
