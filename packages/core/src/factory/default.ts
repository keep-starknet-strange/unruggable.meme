import { Fraction, Percent } from '@uniswap/sdk-core'
import { CallData, getChecksumAddress, hash, shortString, stark, uint256 } from 'starknet'

import {
  AmmInfos,
  DECIMALS,
  EKUBO_BOUND,
  EKUBO_FEES_MULTIPLICATOR,
  EKUBO_TICK_SPACING,
  FACTORY_ADDRESSES,
  LiquidityType,
  QUOTE_TOKENS,
  Selector,
  TOKEN_CLASS_HASH,
} from '../constants'
import {
  BaseMemecoin,
  EkuboLaunchData,
  EkuboLiquidity,
  JediswapLiquidity,
  LaunchedMemecoin,
  Memecoin,
  MemecoinDeployData,
  StandardAMMLaunchData,
} from '../types/memecoin'
import { multiCallContract } from '../utils/contract'
import { getInitialPrice, getStartingTick } from '../utils/ekubo'
import { decimalsScale } from '../utils/helpers'
import { getEkuboLiquidityLockPosition, getJediswapLiquidityLockPosition } from '../utils/liquidity'
import { getPairPrice } from '../utils/token'
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

  public async getMemecoinLaunchData(address: string): Promise<LaunchedMemecoin> {
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

  public getDeployCalldata(data: MemecoinDeployData) {
    const salt = stark.randomAddress()

    const constructorCalldata = CallData.compile([
      data.owner,
      data.name,
      data.symbol,
      uint256.bnToUint256(BigInt(data.initialSupply) * BigInt(decimalsScale(DECIMALS))),
      salt,
    ])

    const tokenAddress = hash.calculateContractAddressFromHash(
      salt,
      TOKEN_CLASS_HASH[this.config.chainId],
      constructorCalldata.slice(0, -1),
      FACTORY_ADDRESSES[this.config.chainId],
    )

    const calls = [
      {
        contractAddress: FACTORY_ADDRESSES[this.config.chainId],
        entrypoint: Selector.CREATE_MEMECOIN,
        calldata: constructorCalldata,
      },
    ]

    return { tokenAddress, calls }
  }

  public async getEkuboLaunchCalldata(memecoin: Memecoin, data: EkuboLaunchData) {
    const quoteTokenPrice = await getPairPrice(this.config.provider, data.quoteToken.usdcPair)

    const teamAllocationFraction = data.teamAllocations.reduce((acc, { amount }) => acc.add(amount), new Fraction(0))
    const teamAllocationPercentage = new Percent(
      teamAllocationFraction.quotient,
      new Fraction(memecoin.totalSupply.toString(), decimalsScale(DECIMALS)).quotient,
    )
    const teamAllocationQuoteAmount = new Fraction(data.startingMarketCap.toString())
      .divide(quoteTokenPrice)
      .multiply(teamAllocationPercentage.multiply(data.fees.add(1)))
    const uin256TeamAllocationQuoteAmount = uint256.bnToUint256(
      BigInt(teamAllocationQuoteAmount.multiply(decimalsScale(DECIMALS)).quotient.toString()),
    )

    const initialPrice = +new Fraction(data.startingMarketCap)
      .divide(quoteTokenPrice)
      .multiply(decimalsScale(DECIMALS))
      .divide(new Fraction(memecoin.totalSupply.toString()))
      .toFixed(DECIMALS)
    const startingTickMag = getStartingTick(initialPrice)
    const i129StartingTick = {
      mag: Math.abs(startingTickMag),
      sign: startingTickMag < 0,
    }

    const fees = data.fees.multiply(EKUBO_FEES_MULTIPLICATOR).quotient.toString()

    const transferCalldata = CallData.compile([
      FACTORY_ADDRESSES[this.config.chainId], // recipient
      uin256TeamAllocationQuoteAmount, // amount
    ])

    const initialHolders = data.teamAllocations.map(({ address }) => address)
    const initialHoldersAmounts = data.teamAllocations.map(({ amount }) =>
      uint256.bnToUint256(BigInt(amount) * BigInt(decimalsScale(DECIMALS))),
    )

    const launchCalldata = CallData.compile([
      data.address, // memecoin address
      data.antiBotPeriod * 60, // anti bot period in seconds
      data.holdLimit * 100, // hold limit
      data.quoteToken.address, // quote token address
      initialHolders, // initial holders
      initialHoldersAmounts, // initial holders amounts
      fees, // ekubo fees
      EKUBO_TICK_SPACING, // tick spacing
      i129StartingTick, // starting tick
      EKUBO_BOUND, // bound
    ])

    const calls = [
      {
        contractAddress: data.quoteToken.address,
        entrypoint: Selector.TRANSFER,
        calldata: transferCalldata,
      },
      {
        contractAddress: FACTORY_ADDRESSES[this.config.chainId],
        entrypoint: Selector.LAUNCH_ON_EKUBO,
        calldata: launchCalldata,
      },
    ]

    return {
      calls,
    }
  }

  public async getStandardAMMLaunchCalldata(memecoin: Memecoin, data: StandardAMMLaunchData) {
    const quoteTokenPrice = await getPairPrice(this.config.provider, data.quoteToken.usdcPair)

    const teamAllocationFraction = data.teamAllocations.reduce((acc, { amount }) => acc.add(amount), new Fraction(0))
    const teamAllocationPercentage = new Percent(
      teamAllocationFraction.quotient,
      new Fraction(memecoin.totalSupply.toString(), decimalsScale(DECIMALS)).quotient,
    )

    const quoteAmount = new Fraction(data.startingMarketCap)
      .divide(quoteTokenPrice)
      .multiply(new Fraction(1).subtract(teamAllocationPercentage))
    const uin256QuoteAmount = uint256.bnToUint256(BigInt(quoteAmount.multiply(decimalsScale(18)).quotient.toString()))

    const initialHolders = data.teamAllocations.map(({ address }) => address)
    const initialHoldersAmounts = data.teamAllocations.map(({ amount }) =>
      uint256.bnToUint256(BigInt(amount) * BigInt(decimalsScale(DECIMALS))),
    )
    const approveCalldata = CallData.compile([
      FACTORY_ADDRESSES[this.config.chainId], // spender
      uin256QuoteAmount,
    ])

    const launchCalldata = CallData.compile([
      data.address, // memecoin address
      data.antiBotPeriod * 60, // anti bot period in seconds
      data.holdLimit * 100, // hold limit
      data.quoteToken.address, // quote token
      initialHolders, // initial holders
      initialHoldersAmounts, // intial holders amounts
      uin256QuoteAmount, // quote amount
      data.liquidityLockPeriod,
    ])

    const calls = [
      {
        contractAddress: data.quoteToken.address,
        entrypoint: Selector.APPROVE,
        calldata: approveCalldata,
      },
      {
        contractAddress: FACTORY_ADDRESSES[this.config.chainId],
        entrypoint: AmmInfos[data.amm].launchEntrypoint,
        calldata: launchCalldata,
      },
    ]

    return {
      calls,
    }
  }
}
