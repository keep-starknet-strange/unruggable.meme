import { Fraction } from '@uniswap/sdk-core'
import { BlockNumber, BlockTag, ProviderInterface, uint256 } from 'starknet'

import { Selector } from '../constants'
import { USDCPair } from '../types/tokens'
import { decimalsScale } from './helpers'

export async function getUSDCPairPrice(
  provider: ProviderInterface,
  usdcPair?: USDCPair,
  blockNumber: BlockNumber = BlockTag.latest,
) {
  if (!usdcPair) return new Fraction(1, 1)

  const { result } = await provider.callContract(
    {
      contractAddress: usdcPair.address,
      entrypoint: Selector.GET_RESERVES,
    },
    blockNumber,
  )

  const [reserve0Low, reserve0High, reserve1Low, reserve1High] = result

  const pairPrice = new Fraction(
    uint256.uint256ToBN({ low: reserve0Low, high: reserve0High }).toString(),
    uint256.uint256ToBN({ low: reserve1Low, high: reserve1High }).toString(),
  )

  // token0 and token1 are switched on some pairs
  return (usdcPair.reversed ? pairPrice.invert() : pairPrice).multiply(decimalsScale(12))
}
