import { constants, RpcProvider } from 'starknet'
import { expect, test } from 'vitest'

import * as TestData from '../../test/TestData'
import { Factory } from '../factory/default'
import { getStartingMarketCap } from './marketCap'
import { getPairPrice } from './price'

const provider = new RpcProvider({
  nodeUrl: 'https://starknet-mainnet.public.blastapi.io',
})

const factory = new Factory({ provider, chainId: constants.StarknetChainId.SN_MAIN })

test('Starting Market Cap', async () => {
  const memecoin = await factory.getMemecoin(TestData.launched.address)

  expect(memecoin).toBeDefined()
  expect(memecoin?.isLaunched).toBe(true)
  if (!memecoin || !memecoin.isLaunched) return

  const quoteTokenPrice = await getPairPrice(
    factory.config.provider,
    memecoin.quoteToken?.usdcPair,
    memecoin.launch.blockNumber - 1,
  )
  const startingMarketCap = getStartingMarketCap(memecoin, quoteTokenPrice)

  expect(startingMarketCap?.toFixed(0)).toBe('4972')
})
