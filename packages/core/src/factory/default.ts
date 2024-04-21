import { Fraction } from '@uniswap/sdk-core'
import { getChecksumAddress, shortString, uint256 } from 'starknet'

import { DECIMALS, FACTORY_ADDRESSES, LiquidityType, QUOTE_TOKENS, Selector } from '../constants'
import { BaseMemecoin, EkuboLiquidity, JediswapLiquidity, Memecoin, MemecoinLaunchData } from '../types/memecoin'
import { multiCallContract } from '../utils/contract'
import { getInitialPrice } from '../utils/ekubo'
import { decimalsScale } from '../utils/helpers'
import { getEkuboLiquidityLockPosition, getJediswapLiquidityLockPosition } from '../utils/liquidity'
import { FactoryConfig, FactoryInterface } from './interface'

export class Factory implements FactoryInterface {
  public config: FactoryConfig

  constructor(config: FactoryConfig) {
    this.config = config
  }

  public async getMemecoin(address: string): Promise<Memecoin | undefined> {
    const [baseMemecoin, launchData] = await Promise.all([
      this.getBaseMemecoin(address),
      this.getMemecoinLaunchData(address),
    ])

    if (!baseMemecoin) return undefined

    return { ...baseMemecoin, ...launchData }
  }

  public async getBaseMemecoin(address: string): Promise<BaseMemecoin | undefined> {
    const result = await multiCallContract(this.config.provider, this.config.chainId, [
      {
        to: FACTORY_ADDRESSES[this.config.chainId],
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

  public async getMemecoinLaunchData(address: string): Promise<MemecoinLaunchData> {
    const result = await multiCallContract(this.config.provider, this.config.chainId, [
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
        to: FACTORY_ADDRESSES[this.config.chainId],
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
          ...(await getJediswapLiquidityLockPosition(this.config.provider, baseLiquidity)),
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
          ...(await getEkuboLiquidityLockPosition(this.config.provider, baseLiquidity)),
        }
      }
    }

    return {
      isLaunched: true,
      quoteToken: QUOTE_TOKENS[this.config.chainId][liquidity.quoteToken],
      teamAllocation: uint256.uint256ToBN({ low: teamAllocation[0], high: teamAllocation[1] }),
      blockNumber: Number(launchBlockNumber),
      liquidity,
    }
  }

  public getStartingMarketCap(memecoin: Memecoin, quoteTokenPriceAtLaunch?: Fraction): Fraction | undefined {
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
}
