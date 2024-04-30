import { renderHook, waitFor } from '@testing-library/react'
import { Ether } from 'core/constants'
import { constants } from 'starknet'
import { describe, expect, test } from 'vitest'

import { wrapper } from '../../test/wrapper'
import { usePairPrice } from './usePairPrice'

describe('usePairPrice', () => {
  test('No pair', async () => {
    const { result } = renderHook(() => usePairPrice({}), { wrapper })

    await waitFor(() => expect(result.current.isSuccess).toBe(false))
    expect(result.current.data).not.toBeDefined()
  })

  test('USDC Pair', async () => {
    const { result } = renderHook(
      () => usePairPrice({ pair: Ether[constants.StarknetChainId.SN_MAIN].usdcPair, blockNumber: 500_000 }),
      {
        wrapper,
      },
    )

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data?.toFixed(0)).toBe('2309')
  })
})
