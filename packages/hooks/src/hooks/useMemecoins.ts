import { UseQueryResult } from '@tanstack/react-query'
import { Memecoin } from 'core'

import { UseQueryProps } from '../types'
import { useQueries } from './internal/useQueries'
import { useFactory } from './useFactory'

// eslint-disable-next-line import/no-unused-modules
export type UseMemecoinsProps = UseQueryProps & {
  addresses: string[]
}

// eslint-disable-next-line import/no-unused-modules
export function useMemecoins({
  addresses,
  enabled,
  watch,
  ...props
}: UseMemecoinsProps): UseQueryResult<Memecoin | undefined, Error | null>[] {
  const factory = useFactory()

  return useQueries({
    queries: addresses.map((address) => ({
      queryKey: ['memecoin', address],
      queryFn: async () => (address ? factory.getMemecoin(address) : undefined),
      ...props,
    })),
    enabled: enabled && Boolean(addresses.length),
    watch,
  })
}
