import { useBlockNumber } from '@starknet-react/core'
import { QueryKey, useQueryClient } from '@tanstack/react-query'
import { useEffect, useRef } from 'react'
import { STARKNET_BLOCK_POLLING } from 'src/constants/misc'

/**
 * Invalidates the given query keys on every new block.
 */
export function useInvalidateOnBlock({
  enabled = true,
  queryKey,
  queryKeys,
}: {
  enabled?: boolean
  queryKey?: QueryKey
  queryKeys?: QueryKey[]
}) {
  const queryClient = useQueryClient()

  const prevBlockNumber = useRef<number | undefined>()

  const { data: blockNumber } = useBlockNumber({
    enabled,
    refetchInterval: STARKNET_BLOCK_POLLING,
  })

  useEffect(() => {
    if (prevBlockNumber.current === undefined) {
      prevBlockNumber.current = blockNumber
      return
    }

    if (blockNumber !== prevBlockNumber.current) {
      prevBlockNumber.current = blockNumber

      if (queryKey) {
        queryClient.invalidateQueries({ queryKey }, { cancelRefetch: false })
      }

      if (queryKeys) {
        queryKeys.forEach((key) => {
          queryClient.invalidateQueries({ queryKey: key }, { cancelRefetch: false })
        })
      }
    }
  }, [blockNumber, prevBlockNumber, queryClient, queryKey])
}
