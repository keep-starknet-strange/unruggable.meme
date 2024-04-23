import { Fraction } from '@uniswap/sdk-core'
import { getChecksumAddress, ProviderInterface } from 'starknet'

import { DECIMALS, LIQUIDITY_LOCK_FOREVER_TIMESTAMP, LiquidityType, Selector } from '../constants'
import { EkuboLiquidity, JediswapLiquidity, Memecoin } from '../types/memecoin'
import { getInitialPrice } from '../utils/ekubo'
import { decimalsScale } from '../utils/helpers'

export async function getJediswapLiquidityLockPosition(
  provider: ProviderInterface,
  liquidity: Pick<JediswapLiquidity, 'lockManager' | 'lockPosition'>,
) {
  const { result } = await provider.callContract({
    contractAddress: liquidity.lockManager,
    entrypoint: Selector.GET_LOCK_DETAILS,
    calldata: [liquidity.lockPosition],
  })

  return {
    unlockTime: +result[4],
    owner: getChecksumAddress(result[3]),
  } satisfies Partial<JediswapLiquidity>
}

export async function getEkuboLiquidityLockPosition(
  provider: ProviderInterface,
  liquidity: Pick<EkuboLiquidity, 'lockManager' | 'ekuboId'>,
) {
  const { result } = await provider.callContract({
    contractAddress: liquidity.lockManager,
    entrypoint: Selector.LIQUIDITY_POSITION_DETAILS,
    calldata: [liquidity.ekuboId],
  })

  return {
    unlockTime: LIQUIDITY_LOCK_FOREVER_TIMESTAMP,
    owner: getChecksumAddress(result[0]),
    poolKey: {
      token0: getChecksumAddress(result[2]),
      token1: getChecksumAddress(result[3]),
      fee: result[4],
      tickSpacing: result[5],
      extension: result[6],
    },
    bounds: {
      lower: {
        mag: result[7],
        sign: result[8],
      },
      upper: {
        mag: result[9],
        sign: result[10],
      },
    },
  } satisfies Partial<EkuboLiquidity>
}

export function getStartingMarketCap(memecoin: Memecoin, quoteTokenPriceAtLaunch?: Fraction): Fraction | undefined {
  if (!memecoin.isLaunched || !quoteTokenPriceAtLaunch) return undefined

  switch (memecoin.liquidity.type) {
    case LiquidityType.STARKDEFI_ERC20:
    case LiquidityType.JEDISWAP_ERC20: {
      if (!memecoin.quoteToken) break

      return new Fraction(memecoin.liquidity.quoteAmount.toString())
        .multiply(new Fraction(memecoin.teamAllocation.toString(), memecoin.totalSupply.toString()).add(1))
        .divide(decimalsScale(memecoin.quoteToken.decimals))
        .multiply(quoteTokenPriceAtLaunch)
    }

    case LiquidityType.EKUBO_NFT: {
      if (!memecoin.quoteToken) break

      const initialPrice = getInitialPrice(memecoin.liquidity.startingTick)
      return new Fraction(
        initialPrice.toFixed(DECIMALS).replace(/\./, '').replace(/^0+/, ''), // from 0.000[...]0001 to "1"
        decimalsScale(DECIMALS),
      )
        .multiply(quoteTokenPriceAtLaunch)
        .multiply(memecoin.totalSupply.toString())
        .divide(decimalsScale(DECIMALS))
    }
  }

  return undefined
}
