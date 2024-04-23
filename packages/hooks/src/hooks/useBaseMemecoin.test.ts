import { renderHook, waitFor } from '@testing-library/react'
import { describe, expect, test } from 'vitest'

import * as TestData from '../../test/TestData'
import { wrapper } from '../../test/wrapper'
import { useBaseMemecoin } from './useBaseMemecoin'

describe('useBaseMemecoin', () => {
  test('Not Launched', async () => {
    const { result } = renderHook(() => useBaseMemecoin({ address: TestData.notLaunched.address }), { wrapper })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(TestData.notLaunched.baseMemecoin)
  })

  test('Launched', async () => {
    const { result } = renderHook(() => useBaseMemecoin({ address: TestData.launched.address }), { wrapper })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(TestData.launched.baseMemecoin)
  })
})
