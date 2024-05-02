import { QueriesOptions, QueriesResults, useQueries as useReactQueries } from '@tanstack/react-query'
import { useMemo } from 'react'

import { useInvalidateOnBlock } from './useInvalidateOnBlock'
import { useInvalidateOnChanId } from './useInvalidateOnChanId'

export function useQueries<T extends Array<any>, TCombinedResult = QueriesResults<T>>({
  queries,
  watch,
  enabled,
  ...options
}: {
  queries: readonly [...QueriesOptions<T>]
  combine?: (result: QueriesResults<T>) => TCombinedResult
} & {
  enabled?: boolean
  watch?: boolean
}): TCombinedResult {
  const query = useReactQueries({
    queries: queries.map((query) => ({
      ...query,
      enabled,
    })) as unknown as typeof queries,
    ...options,
  })

  const queryKeys = useMemo(() => queries.map((query) => query.queryKey), [queries])

  useInvalidateOnBlock({
    enabled: watch && enabled,
    queryKeys,
  })

  // Data should be refetched no matter if the watch is enabled or not
  useInvalidateOnChanId({
    enabled,
    queryKeys,
  })

  return query
}
