import { getChecksumAddress, ProviderInterface } from 'starknet'

import { LIQUIDITY_LOCK_FOREVER_TIMESTAMP, Selector } from '../constants'
import { EkuboLiquidity, JediswapLiquidity } from '../types/memecoin'

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
