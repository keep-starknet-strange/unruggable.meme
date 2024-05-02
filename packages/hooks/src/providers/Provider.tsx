import { QueryClient } from '@tanstack/react-query'
import { Factory } from 'core'
import { ProviderInterface } from 'starknet'

import { FactoryProvider } from './FactoryProvider'
import { QueryProvider } from './QueryProvider'

export interface ProviderProps {
  /**
   * Factory client to use in the hooks.
   * If not provided, the hooks will use the default factory client.
   * However, it is highly recommended to provide a factory client.
   * If the factory client is provided, the provider interface will be ignored.
   */
  factory?: Factory

  /**
   * Provider Interface to use if the factory client is not provided.
   * If not provided, the hooks will use the default provider interface.
   * If factory client is provided, this prop will be ignored.
   */
  provider?: ProviderInterface

  /** React-query client to use. */
  queryClient?: QueryClient
}

export function Provider({ factory, queryClient, children }: React.PropsWithChildren<ProviderProps>) {
  return (
    <FactoryProvider factory={factory}>
      <QueryProvider queryClient={queryClient}>{children}</QueryProvider>
    </FactoryProvider>
  )
}
