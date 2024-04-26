import { useContext } from 'react'

import { FactoryContext } from '../contexts/Factory'

export function useFactory() {
  const factory = useContext(FactoryContext)

  if (factory === null) {
    throw new Error('Please wrap your app in the Provider component.')
  }

  return factory
}
