import { DefaultError, QueryKey, useQuery as useReactQuery, UseQueryOptions } from '@tanstack/react-query'

import { useInvalidateOnBlock } from './useInvalidateOnBlock'
import { useInvalidateOnChanId } from './useInvalidateOnChanId'

export function useQuery<
  TQueryFnData = unknown,
  TError = DefaultError,
  TData = TQueryFnData,
  TQueryKey extends QueryKey = QueryKey,
>({
  watch,

  enabled,
  queryKey,
  ...props
}: UseQueryOptions<TQueryFnData, TError, TData, TQueryKey> & {
  watch?: boolean
}) {
  const query = useReactQuery({
    queryKey,
    enabled,

    // Stale time doesn't actually matter since we have our own invalidation logic
    // But better to provide than to have it default to 0
    staleTime: 60 * 1000,

    ...props,
  })

  useInvalidateOnBlock({
    enabled: watch && enabled,
    queryKey,
  })

  // Data should be refetched no matter if the watch is enabled or not
  useInvalidateOnChanId({
    enabled,
    queryKey,
  })

  return query
}
