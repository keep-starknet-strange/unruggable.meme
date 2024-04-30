import { renderHook, waitFor } from '@testing-library/react'
import { Ether, USDCoin } from 'core/constants'
import { constants } from 'starknet'
import { describe, expect, test } from 'vitest'

import { wrapper } from '../../test/wrapper'
import { useQuoteTokenPrice } from './useQuoteTokenPrice'

describe('useQuoteTokenPrice', () => {
  test('Unknown Quote Token', async () => {
    const { result } = renderHook(() => useQuoteTokenPrice({ address: '' }), { wrapper })

    await waitFor(() => expect(result.current.isSuccess).toBe(false))
    expect(result.current.data).not.toBeDefined()
  })

  test('USDC Quote Token', async () => {
    const { result } = renderHook(
      () => useQuoteTokenPrice({ address: USDCoin[constants.StarknetChainId.SN_MAIN].address }),
      {
        wrapper,
      },
    )

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toBeDefined()
    expect(result.current.data?.toFixed(0)).toBe('1')
  })

  test('ETH Quote Token', async () => {
    const { result } = renderHook(
      () => useQuoteTokenPrice({ address: Ether[constants.StarknetChainId.SN_MAIN].address, blockNumber: 500_000 }),
      {
        wrapper,
      },
    )

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toBeDefined()
    expect(result.current.data?.toFixed(0)).toBe('2309')
  })
})
