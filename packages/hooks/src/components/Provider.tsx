import { QueryClient } from '@tanstack/react-query'
import { Factory } from 'core'

import { FactoryProvider } from './FactoryProvider'
import { QueryProvider } from './QueryProvider'

export type ProviderProps = {
  /** Factory client to use in the hooks. */
  factory: Factory

  /** React-query client to use. */
  queryClient?: QueryClient

  children?: React.ReactNode
}

export const Provider = ({ factory, queryClient, children }: ProviderProps) => {
  return (
    <FactoryProvider factory={factory}>
      <QueryProvider queryClient={queryClient}>{children}</QueryProvider>
    </FactoryProvider>
  )
}
