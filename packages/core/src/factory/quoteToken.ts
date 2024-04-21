import { Fraction } from '@uniswap/sdk-core'
import { BlockNumber, BlockTag, uint256 } from 'starknet'

import { QUOTE_TOKENS, Selector } from '../constants'
import { Token } from '../types/tokens'
import { decimalsScale } from '../utils/helpers'
import { FactoryConfig } from './interface'

export class QuoteToken {
  private config: FactoryConfig

  public token: Token | undefined

  constructor(config: FactoryConfig, address: string) {
    this.config = config

    this.token = QUOTE_TOKENS[this.config.chainId][address]
  }

  public async getUSDCPrice(blockNumber: BlockNumber = BlockTag.latest) {
    if (!this.token) return

    if (!this.token.usdcPair) return new Fraction(1, 1)

    const { result } = await this.config.provider.callContract(
      {
        contractAddress: this.token.usdcPair?.address,
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
    return (this.token.usdcPair?.reversed ? pairPrice.invert() : pairPrice).multiply(decimalsScale(12))
  }
}
