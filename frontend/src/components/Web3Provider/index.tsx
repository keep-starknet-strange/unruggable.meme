import { sepolia } from '@starknet-react/chains'
import { argent, braavos, publicProvider, StarknetConfig, starkscan, useInjectedConnectors } from '@starknet-react/core'

// STARKNET

interface StarknetProviderProps {
  children: React.ReactNode
}

export function StarknetProvider({ children }: StarknetProviderProps) {
  const { connectors } = useInjectedConnectors({
    recommended: [argent(), braavos()],
    includeRecommended: 'onlyIfNoConnectors',
    order: 'random',
  })

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
