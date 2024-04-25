import { UseQueryResult } from '@tanstack/react-query'
import { BaseMemecoin } from 'core'

import { UseQueryProps } from '../types'
import { useQuery } from './internal/useQuery'
import { useFactory } from './useFactory'

export type UseBaseMemecoinProps = UseQueryProps & {
  address?: string
}

export function useBaseMemecoin({
  address,
  ...props
}: UseBaseMemecoinProps): UseQueryResult<BaseMemecoin | undefined, Error | null> {
  const factory = useFactory()

  return useQuery({
    queryKey: ['baseMemecoin', address],
    queryFn: async () => (address ? factory.getBaseMemecoin(address) : undefined),
    enabled: Boolean(address),
    ...props,
  })
}
