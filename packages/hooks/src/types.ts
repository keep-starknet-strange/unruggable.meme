import { UseQueryOptions } from '@tanstack/react-query'

export type UseQueryProps = Pick<
  UseQueryOptions<any>,
  'enabled' | 'staleTime' | 'refetchInterval' | 'retry' | 'retryDelay'
> & {
  watch?: boolean
}
