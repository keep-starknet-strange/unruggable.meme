import { sepolia } from '@starknet-react/chains'
import { argent, braavos, publicProvider, StarknetConfig, useInjectedConnectors } from '@starknet-react/core'

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
    <StarknetConfig connectors={connectors} chains={[sepolia]} provider={publicProvider()} autoConnect>
      {children}
    </StarknetConfig>
  )
}
