import { useBlockNumber } from '@starknet-react/core'
import { QueryKey, useQueryClient } from '@tanstack/react-query'
import { useEffect, useRef } from 'react'

/**
 * Invalidates the given query keys on every new block.
 */
export function useInvalidateOnBlock({ enabled = true, queryKey }: { enabled?: boolean; queryKey: QueryKey }) {
  const queryClient = useQueryClient()

  const prevBlockNumber = useRef<number | undefined>()

  const { data: blockNumber } = useBlockNumber({
    enabled,
  })

  useEffect(() => {
    if (blockNumber !== prevBlockNumber.current) {
      prevBlockNumber.current = blockNumber

      queryClient.invalidateQueries({ queryKey }, { cancelRefetch: false })
    }
  }, [blockNumber, prevBlockNumber, queryClient, queryKey])
}
