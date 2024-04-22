import { Factory } from 'core'

import { FactoryContext } from '../contexts/Factory'

export type FactoryProviderProps = {
  factory: Factory
  children?: React.ReactNode
}

export const FactoryProvider = ({ factory, children }: FactoryProviderProps) => {
  return <FactoryContext.Provider value={factory}>{children}</FactoryContext.Provider>
}
