import { useNetwork } from '@starknet-react/core'
import { DefaultError, QueryKey, useQuery as useReactQuery, UseQueryOptions } from '@tanstack/react-query'
import { useEffect } from 'react'

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

  // refetch on chainId update
  const { chain } = useNetwork()
  useEffect(() => {
    if (chain.id && enabled) {
      query.refetch()
    }
  }, [chain.id])

  return query
}
