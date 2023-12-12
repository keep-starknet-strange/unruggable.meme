import { InjectedConnector, StarknetConfig } from '@starknet-react/core'
import { useMemo } from 'react'
import { getL2Connections } from 'src/connections'

// STARKNET

interface StarknetProviderProps {
  children: React.ReactNode
}

export function StarknetProvider({ children }: StarknetProviderProps) {
  const connections = getL2Connections()
  const connectors: InjectedConnector[] = connections.map(({ connector }) => connector)

  const key = useMemo(() => connections.map((connection) => connection.getName()).join('-'), [connections])

  return (
    <StarknetConfig connectors={connectors} key={key} autoConnect>
      {children}
    </StarknetConfig>
  )
}
