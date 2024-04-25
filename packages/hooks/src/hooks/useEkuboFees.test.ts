import { renderHook, waitFor } from '@testing-library/react'
import { Fraction } from '@uniswap/sdk-core'
import { describe, expect, test } from 'vitest'

import * as TestData from '../../test/TestData'
import { wrapper } from '../../test/wrapper'
import { useEkuboFees } from './useEkuboFees'

describe('useEkuboFees', () => {
  test('USDC Pair', async () => {
    const { result } = renderHook(() => useEkuboFees({ address: TestData.launched.address }), { wrapper })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toBeInstanceOf(Fraction)
  })
})
