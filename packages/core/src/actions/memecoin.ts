import { getChecksumAddress, shortString, uint256 } from 'starknet'

import { DECIMALS, FACTORY_ADDRESSES, LiquidityType, QUOTE_TOKENS, Selector } from '../constants'
import { FactoryConfig } from '../factory'
import { BaseMemecoin, EkuboLiquidity, JediswapLiquidity, LaunchedMemecoin } from '../types'
import { multiCallContract } from '../utils/contract'
import { getEkuboLiquidityLockPosition, getJediswapLiquidityLockPosition } from './liquidity'

export async function getBaseMemecoin(config: FactoryConfig, address: string): Promise<BaseMemecoin | undefined> {
  const result = await multiCallContract(config.provider, config.chainId, [
    {
      to: FACTORY_ADDRESSES[config.chainId],
      selector: Selector.IS_MEMECOIN,
      calldata: [address],
    },
    {
      to: address,
      selector: Selector.NAME,
    },
    {
      to: address,
      selector: Selector.SYMBOL,
    },
    {
      to: address,
      selector: Selector.OWNER,
    },
    {
      to: address,
      selector: Selector.TOTAL_SUPPLY,
    },
  ])

  const [[isMemecoin], [name], [symbol], [owner], totalSupply] = result

  if (!+isMemecoin) return undefined

  return {
    address,
    name: shortString.decodeShortString(name),
    symbol: shortString.decodeShortString(symbol),
    owner: getChecksumAddress(owner),
    decimals: DECIMALS,
    totalSupply: uint256.uint256ToBN({ low: totalSupply[0], high: totalSupply[1] }),
  }
}

export async function getMemecoinLaunchData(config: FactoryConfig, address: string): Promise<LaunchedMemecoin> {
  const result = await multiCallContract(config.provider, config.chainId, [
    {
      to: address,
      selector: Selector.GET_TEAM_ALLOCATION,
    },
    {
      to: address,
      selector: Selector.LAUNCHED_AT_BLOCK_NUMBER,
    },
    {
      to: address,
      selector: Selector.IS_LAUNCHED,
    },
    {
      to: FACTORY_ADDRESSES[config.chainId],
      selector: Selector.LOCKED_LIQUIDITY,
      calldata: [address],
    },
    {
      to: address,
      selector: Selector.LAUNCHED_WITH_LIQUIDITY_PARAMETERS,
    },
  ])

  const [
    teamAllocation,
    [launchBlockNumber],
    [launched],
    [dontHaveLiq, lockManager, liqTypeIndex, ekuboId],
    launchParams,
  ] = result

  const liquidityType = Object.values(LiquidityType)[+liqTypeIndex] as LiquidityType

  const isLaunched = !!+launched && !+dontHaveLiq && !+launchParams[0] && liquidityType

  if (!isLaunched) {
    return {
      isLaunched: false,
    }
  }

  let liquidity
  switch (liquidityType) {
    case LiquidityType.STARKDEFI_ERC20:
    case LiquidityType.JEDISWAP_ERC20: {
      const baseLiquidity = {
        type: liquidityType,
        lockManager,
        lockPosition: launchParams[5],
        quoteToken: getChecksumAddress(launchParams[2]),
        quoteAmount: uint256.uint256ToBN({ low: launchParams[3], high: launchParams[4] }),
      } satisfies Partial<JediswapLiquidity>

      liquidity = {
        ...baseLiquidity,
        ...(await getJediswapLiquidityLockPosition(config.provider, baseLiquidity)),
      }
      break
    }

    case LiquidityType.EKUBO_NFT: {
      const baseLiquidity = {
        type: liquidityType,
        lockManager,
        ekuboId,
        quoteToken: getChecksumAddress(launchParams[7]),
        startingTick: +launchParams[4] * (+launchParams[5] ? -1 : 1), // mag * sign
      } satisfies Partial<EkuboLiquidity>

      liquidity = {
        ...baseLiquidity,
        ...(await getEkuboLiquidityLockPosition(config.provider, baseLiquidity)),
      }
    }
  }

  return {
    isLaunched: true,
    quoteToken: QUOTE_TOKENS[config.chainId][liquidity.quoteToken],
    teamAllocation: uint256.uint256ToBN({ low: teamAllocation[0], high: teamAllocation[1] }),
    blockNumber: Number(launchBlockNumber),
    liquidity,
  }
}
