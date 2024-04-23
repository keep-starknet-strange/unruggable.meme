import { starknetChainId, useNetwork, useProvider } from '@starknet-react/core'
import { Factory } from 'core'
import { useEffect, useRef } from 'react'
import { ProviderInterface } from 'starknet'

import { FactoryContext } from '../contexts/Factory'

type FactoryProviderProps = {
  factory?: Factory
  provider?: ProviderInterface
  children?: React.ReactNode
}

export const FactoryProvider = ({ factory, provider, children }: FactoryProviderProps) => {
  const defaultFactory = useRef<Factory | undefined>()

  const { provider: defaultProvider } = useProvider()
  const { chain } = useNetwork()

  useEffect(() => {
    // If a factory is provided, use it instead of creating a new one.
    if (factory) return

    const chainId = chain.id ? starknetChainId(chain.id) : undefined
    if (!chainId || !(provider ?? defaultProvider)) return

    defaultFactory.current = new Factory({ provider: provider ?? defaultProvider, chainId })
  }, [factory, provider, defaultProvider, chain.id])

  const factoryToUse = factory ?? defaultFactory.current

  if (!factoryToUse) return children

  return <FactoryContext.Provider value={factoryToUse}>{children}</FactoryContext.Provider>
}
