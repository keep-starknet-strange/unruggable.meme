import { renderHook, waitFor } from '@testing-library/react'
import { Ether, USDCoin } from 'core/constants'
import { constants } from 'starknet'
import { describe, expect, test } from 'vitest'

import { wrapper } from '../../test/wrapper'
import { useQuoteTokenPrice } from './useQuoteTokenPrice'

describe('useQuoteTokenPrice', () => {
  test('Unknown Quote Token', async () => {
    const { result } = renderHook(() => useQuoteTokenPrice(''), { wrapper })

    expect(result.current).not.toBeDefined()
  })

  test('USDC Quote Token', async () => {
    const { result } = renderHook(() => useQuoteTokenPrice(USDCoin[constants.StarknetChainId.SN_MAIN].address), {
      wrapper,
    })

    expect(result.current).toBeDefined()
    expect(result.current?.toFixed(0)).toBe('1')
  })

  test('ETH Quote Token', async () => {
    const { result } = renderHook(() => useQuoteTokenPrice(Ether[constants.StarknetChainId.SN_MAIN].address, 500_000), {
      wrapper,
    })

    await waitFor(() => expect(result.current).toBeDefined())
    expect(result.current?.toFixed(0)).toBe('2309')
  })
})
