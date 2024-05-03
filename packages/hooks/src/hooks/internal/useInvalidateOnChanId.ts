import { useNetwork } from '@starknet-react/core'
import { QueryKey, useQueryClient } from '@tanstack/react-query'
import { useEffect, useRef } from 'react'

/**
 * Invalidates the given query keys on chain id change.
 */
export function useInvalidateOnChanId({
  enabled = true,
  queryKey,
  queryKeys,
}: {
  enabled?: boolean
  queryKey?: QueryKey
  queryKeys?: QueryKey[]
}) {
  const queryClient = useQueryClient()

  const { chain } = useNetwork()

  const prevChanId = useRef<bigint | undefined>()

  useEffect(() => {
    if (prevChanId.current === undefined) {
      prevChanId.current = chain.id
      return
    }

    if (enabled && prevChanId.current !== chain.id) {
      prevChanId.current = chain.id

      if (queryKey) {
        queryClient.invalidateQueries({ queryKey }, { cancelRefetch: false })
      }

      if (queryKeys) {
        queryKeys.forEach((key) => {
          queryClient.invalidateQueries({ queryKey: key }, { cancelRefetch: false })
        })
      }
    }
  }, [enabled, prevChanId, chain.id, queryKey, queryKeys])
}
