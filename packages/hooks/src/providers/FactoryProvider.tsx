import { starknetChainId, useNetwork, useProvider } from '@starknet-react/core'
import { Factory } from 'core'
import { useMemo } from 'react'
import { ProviderInterface, constants } from 'starknet'

import { FactoryContext } from '../contexts/Factory'

type FactoryProviderProps = {
  factory?: Factory
  provider?: ProviderInterface
  children?: React.ReactNode
}

export const FactoryProvider = ({ factory, provider, children }: FactoryProviderProps) => {
  const { provider: defaultProvider } = useProvider()
  const { chain } = useNetwork()

  const factoryToUse = useMemo(() => {
    // If a factory is provided, use it instead of creating a new one.
    if (factory) return factory

    const chainId = chain.id ? starknetChainId(chain.id) : undefined
    if (!chainId) {
      return new Factory({ provider: provider ?? defaultProvider, chainId: constants.StarknetChainId.SN_MAIN })
    }

    return new Factory({ provider: provider ?? defaultProvider, chainId })
  }, [chain.id, provider, defaultProvider, factory])

  return <FactoryContext.Provider value={factoryToUse}>{children}</FactoryContext.Provider>
}
