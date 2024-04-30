import { Fraction } from '@uniswap/sdk-core'

import { DECIMALS, LiquidityType } from '../constants'
import { Memecoin } from '../types'
import { getInitialPrice } from './ekubo'
import { decimalsScale } from './helpers'

// eslint-disable-next-line import/no-unused-modules
export function getStartingMarketCap(memecoin: Memecoin, quoteTokenPriceAtLaunch?: Fraction): Fraction | undefined {
  if (!memecoin.isLaunched || !quoteTokenPriceAtLaunch || !memecoin.quoteToken) return undefined

  switch (memecoin.liquidity.type) {
    case LiquidityType.STARKDEFI_ERC20:
    case LiquidityType.JEDISWAP_ERC20: {
      // starting mcap = quote amount in liq * (team allocation % + 100) * quote token price at launch
      return new Fraction(memecoin.liquidity.quoteAmount)
        .multiply(new Fraction(memecoin.launch.teamAllocation, memecoin.totalSupply).add(1))
        .divide(decimalsScale(memecoin.quoteToken.decimals))
        .multiply(quoteTokenPriceAtLaunch)
    }

    case LiquidityType.EKUBO_NFT: {
      // get starting price from starting tick
      const initialPrice = getInitialPrice(memecoin.liquidity.startingTick)

      // starting mcap = initial price * quote token price at launch * total supply
      return new Fraction(
        initialPrice.toFixed(DECIMALS).replace(/\./, '').replace(/^0+/, ''), // from 0.000[...]0001 to "1"
        decimalsScale(DECIMALS),
      )
        .multiply(quoteTokenPriceAtLaunch)
        .multiply(memecoin.totalSupply)
        .divide(decimalsScale(DECIMALS))
    }
  }
}
