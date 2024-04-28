import { CallContractResponse, CallData, getChecksumAddress, hash, shortString, uint256 } from 'starknet'

import { provider } from '../services/provider'
import { LiquidityType, Memecoin } from '../types'
import { FACTORY_ADDRESS, MULTICALL_ADDRESS, Selector } from './constants'
import { getEkuboLiquidityLockPosition, getJediswapLiquidityLockPosition } from './liquidity'

export async function getTokenData(tokenAddress: string) {
  const isMemecoinCalldata = CallData.compile({
    to: FACTORY_ADDRESS,
    selector: hash.getSelector(Selector.IS_MEMECOIN),
    calldata: [tokenAddress],
  })

  const nameCalldata = CallData.compile({
    to: tokenAddress,
    selector: hash.getSelector(Selector.NAME),
    calldata: [],
  })

  const symbolCalldata = CallData.compile({
    to: tokenAddress,
    selector: hash.getSelector(Selector.SYMBOL),
    calldata: [],
  })

  const launchedCalldata = CallData.compile({
    to: tokenAddress,
    selector: hash.getSelector(Selector.IS_LAUNCHED),
    calldata: [],
  })

  const totalSupplyCalldata = CallData.compile({
    to: tokenAddress,
    selector: hash.getSelector(Selector.TOTAL_SUPPLY),
    calldata: [],
  })

  const teamAllocationCalldata = CallData.compile({
    to: tokenAddress,
    selector: hash.getSelector(Selector.GET_TEAM_ALLOCATION),
    calldata: [],
  })

  const ownerCalldata = CallData.compile({
    to: tokenAddress,
    selector: hash.getSelector(Selector.OWNER),
    calldata: [],
  })

  const lockedLiquidity = CallData.compile({
    to: FACTORY_ADDRESS,
    selector: hash.getSelector(Selector.LOCKED_LIQUIDITY),
    calldata: [tokenAddress],
  })

  const launchBlock = CallData.compile({
    to: tokenAddress,
    selector: hash.getSelector(Selector.LAUNCHED_AT_BLOCK_NUMBER),
    calldata: [],
  })

  const launchParams = CallData.compile({
    to: tokenAddress,
    selector: hash.getSelector(Selector.LAUNCHED_WITH_LIQUIDITY_PARAMETERS),
    calldata: [],
  })

  return provider.callContract({
    contractAddress: MULTICALL_ADDRESS,
    entrypoint: Selector.AGGREGATE,
    calldata: [
      10,
      ...isMemecoinCalldata,
      ...nameCalldata,
      ...symbolCalldata,
      ...launchedCalldata,
      ...totalSupplyCalldata,
      ...teamAllocationCalldata,
      ...ownerCalldata,
      ...lockedLiquidity,
      ...launchBlock,
      ...launchParams,
    ],
  })
}

export async function parseTokenData(tokenAddress: string, res: CallContractResponse): Promise<Memecoin | null> {
  const isUnruggable = !!+res.result[3] // beautiful

  if (!isUnruggable) return null

  const hasLiquidity = !+res.result[19] // even more beautiful
  const hasLaunchParams = !+res.result[26] // I'm delighted

  const isLaunched = !!+res.result[9] && hasLiquidity && hasLaunchParams // meh...

  const baseMemecoin = {
    address: tokenAddress,
    name: shortString.decodeShortString(res.result[5]),
    symbol: shortString.decodeShortString(res.result[7]),
    totalSupply: uint256.uint256ToBN({ low: res.result[11], high: res.result[12] }).toString(),
    owner: getChecksumAddress(res.result[17]),
  }

  if (isLaunched) {
    const launch = {
      teamAllocation: uint256.uint256ToBN({ low: res.result[14], high: res.result[15] }).toString(),
      blockNumber: +res.result[24],
    }

    const liquidityType = Object.values(LiquidityType)[+res.result[21]] as LiquidityType

    const lockManager = res.result[20] as string

    switch (liquidityType) {
      case LiquidityType.STARKDEFI_ERC20:
      case LiquidityType.JEDISWAP_ERC20: {
        const liquidity = {
          type: liquidityType,
          lockManager,
          lockPosition: res.result[31],
          quoteToken: getChecksumAddress(res.result[28]),
          quoteAmount: uint256.uint256ToBN({ low: res.result[29], high: res.result[30] }).toString(),
        } as const

        return {
          ...baseMemecoin,
          isLaunched: true,
          launch,
          liquidity: {
            ...liquidity,
            ...(await getJediswapLiquidityLockPosition(liquidity)),
          },
        }
      }

      case LiquidityType.EKUBO_NFT: {
        const liquidity = {
          type: LiquidityType.EKUBO_NFT,
          lockManager,
          ekuboId: res.result[22],
          quoteToken: getChecksumAddress(res.result[33]),
          startingTick: +res.result[30] * (+res.result[31] ? -1 : 1), // mag * sign
        } as const

        return {
          ...baseMemecoin,
          isLaunched: true,
          launch,
          liquidity: {
            ...liquidity,
            ...(await getEkuboLiquidityLockPosition(liquidity)),
          },
        }
      }
    }
  } else {
    return { ...baseMemecoin, isLaunched: false }
  }
}
