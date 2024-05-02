import { constants, RpcProvider } from 'starknet'
import { describe, expect, test } from 'vitest'

import { Ether } from '../constants'
import { getPairPrice } from './price'

const provider = new RpcProvider({
  nodeUrl: 'https://starknet-mainnet.public.blastapi.io',
})

describe('Price', () => {
  test('No pair', async () => {
    const price = await getPairPrice(provider)

    expect(price.toFixed(0)).toBe('1')
  })

  test('USDC Pair', async () => {
    const price = await getPairPrice(provider, Ether[constants.StarknetChainId.SN_MAIN].usdcPair, 500_000)

    expect(price.toFixed(0)).toBe('2309')
  })
})
