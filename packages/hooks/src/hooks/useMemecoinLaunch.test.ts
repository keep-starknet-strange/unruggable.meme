import { renderHook, waitFor } from '@testing-library/react'
import { describe, expect, test } from 'vitest'

import * as TestData from '../../test/TestData'
import { wrapper } from '../../test/wrapper'
import { useMemecoinLaunch } from './useMemecoinLaunch'

describe('useMemecoinLaunch', () => {
  test('Not Launched', async () => {
    const { result } = renderHook(() => useMemecoinLaunch({ address: TestData.notLaunched.address }), { wrapper })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toEqual(TestData.notLaunched.launchData)
  })

  test('Launched', async () => {
    const { result } = renderHook(() => useMemecoinLaunch({ address: TestData.launched.address }), { wrapper })

    await waitFor(() => expect(result.current.isSuccess).toBe(true))
    expect(result.current.data).toMatchObject(TestData.launched.launchData)
  })
})
