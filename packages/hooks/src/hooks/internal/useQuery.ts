import { DefaultError, QueryKey, useQuery as useReactQuery, UseQueryOptions } from '@tanstack/react-query'

import { useInvalidateOnBlock } from './useInvalidateOnBlock'

export const useQuery = <
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
}) => {
  const query = useReactQuery({
    queryKey,
    enabled,
    ...props,
  })

  useInvalidateOnBlock({
    enabled: watch && enabled,
    queryKey,
  })

  return query
}
