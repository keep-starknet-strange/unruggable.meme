import { Fraction, Percent } from '@uniswap/sdk-core'
import { CallData, getChecksumAddress, hash, shortString, stark, uint256 } from 'starknet'

import {
  AMMS,
  DECIMALS,
  EKUBO_BOUND,
  EKUBO_FEES_MULTIPLICATOR,
  EKUBO_POSITIONS_ADDRESSES,
  EKUBO_TICK_SPACING,
  Entrypoint,
  FACTORY_ADDRESSES,
  LIQUIDITY_LOCK_FOREVER_TIMESTAMP,
  LiquidityType,
  QUOTE_TOKENS,
  TOKEN_CLASS_HASH,
} from '../constants'
import {
  BaseMemecoin,
  DeployData,
  EkuboLaunchData,
  EkuboLiquidity,
  JediswapLiquidity,
  LaunchedMemecoin,
  Memecoin,
  StandardAMMLaunchData,
} from '../types/memecoin'
import { multiCallContract } from '../utils/contract'
import { getStartingTick } from '../utils/ekubo'
import { decimalsScale } from '../utils/helpers'
import { getPairPrice } from '../utils/price'
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

  //
  // GET MEMECOIN
  //

  public async getBaseMemecoin(address: string): Promise<BaseMemecoin | undefined> {
    const result = await multiCallContract(this.config.provider, this.config.chainId, [
      {
        contractAddress: FACTORY_ADDRESSES[this.config.chainId],
        entrypoint: Entrypoint.IS_MEMECOIN,
        calldata: [address],
      },
      {
        contractAddress: address,
        entrypoint: Entrypoint.NAME,
      },
      {
        contractAddress: address,
        entrypoint: Entrypoint.SYMBOL,
      },
      {
        contractAddress: address,
        entrypoint: Entrypoint.OWNER,
      },
      {
        contractAddress: address,
        entrypoint: Entrypoint.TOTAL_SUPPLY,
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
      totalSupply: uint256.uint256ToBN({ low: totalSupply[0], high: totalSupply[1] }).toString(),
    }
  }

  //
  // GET LAUNCH
  //

  public async getMemecoinLaunchData(address: string): Promise<LaunchedMemecoin> {
    const result = await multiCallContract(this.config.provider, this.config.chainId, [
      {
        contractAddress: address,
        entrypoint: Entrypoint.GET_TEAM_ALLOCATION,
      },
      {
        contractAddress: address,
        entrypoint: Entrypoint.LAUNCHED_AT_BLOCK_NUMBER,
      },
      {
        contractAddress: address,
        entrypoint: Entrypoint.IS_LAUNCHED,
      },
      {
        contractAddress: FACTORY_ADDRESSES[this.config.chainId],
        entrypoint: Entrypoint.LOCKED_LIQUIDITY,
        calldata: [address],
      },
      {
        contractAddress: address,
        entrypoint: Entrypoint.LAUNCHED_WITH_LIQUIDITY_PARAMETERS,
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
          quoteAmount: uint256.uint256ToBN({ low: launchParams[3], high: launchParams[4] }).toString(),
        } satisfies Partial<JediswapLiquidity>

        liquidity = {
          ...baseLiquidity,
          ...(await this.getJediswapLiquidityLockPosition(baseLiquidity)),
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
          ...(await this.getEkuboLiquidityLockPosition(baseLiquidity)),
        }
      }
    }

    return {
      isLaunched: true,
      quoteToken: QUOTE_TOKENS[this.config.chainId][liquidity.quoteToken],
      launch: {
        teamAllocation: uint256.uint256ToBN({ low: teamAllocation[0], high: teamAllocation[1] }).toString(),
        blockNumber: Number(launchBlockNumber),
      },
      liquidity,
    }
  }

  //
  // GET LIQUIDITY
  //

  private async getJediswapLiquidityLockPosition(liquidity: Pick<JediswapLiquidity, 'lockManager' | 'lockPosition'>) {
    const result = await this.config.provider.callContract({
      contractAddress: liquidity.lockManager,
      entrypoint: Entrypoint.GET_LOCK_DETAILS,
      calldata: [liquidity.lockPosition],
    })

    // TODO: deconstruct result array in cleaner way

    return {
      unlockTime: +result[4],
      owner: getChecksumAddress(result[3]),
    } satisfies Partial<JediswapLiquidity>
  }

  private async getEkuboLiquidityLockPosition(liquidity: Pick<EkuboLiquidity, 'lockManager' | 'ekuboId'>) {
    const result = await this.config.provider.callContract({
      contractAddress: liquidity.lockManager,
      entrypoint: Entrypoint.LIQUIDITY_POSITION_DETAILS,
      calldata: [liquidity.ekuboId],
    })

    // TODO: deconstruct result array in cleaner way

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

  //
  // GET FEES
  //

  public async getEkuboFees(memecoin: Memecoin): Promise<Fraction | undefined> {
    if (!memecoin.isLaunched || memecoin.liquidity.type !== LiquidityType.EKUBO_NFT || !memecoin.quoteToken) return

    const calldata = CallData.compile([
      memecoin.liquidity.ekuboId,
      memecoin.liquidity.poolKey,
      memecoin.liquidity.bounds,
    ])

    // call ekubo position to get collectable fees details
    const result = await this.config.provider.callContract({
      contractAddress: EKUBO_POSITIONS_ADDRESSES[this.config.chainId],
      entrypoint: Entrypoint.GET_TOKEN_INFOS,
      calldata,
    })

    const [, , , , , , , fees0, fees1] = result

    // parse fees amount
    return new Fraction(
      (new Fraction(memecoin.address).lessThan(memecoin.quoteToken.address) ? fees1 : fees0).toString(),
      decimalsScale(memecoin.quoteToken.decimals),
    )
  }

  //
  // GET COLLECT EKUBO FEES CALLDATA
  //

  public getCollectEkuboFeesCalldata(memecoin: Memecoin) {
    if (!memecoin.isLaunched || memecoin.liquidity.type !== LiquidityType.EKUBO_NFT) return

    const collectFeesCalldata = CallData.compile([
      memecoin.liquidity.ekuboId, // ekubo pool id
      memecoin.liquidity.owner,
    ])

    const calls = [
      {
        contractAddress: memecoin.liquidity.lockManager,
        entrypoint: Entrypoint.WITHDRAW_FEES,
        calldata: collectFeesCalldata,
      },
    ]

    return { calls }
  }

  //
  // GET EXTEND LIQUIDITY LOCK CALLDATA
  //

  public getExtendLiquidityLockCalldata(memecoin: Memecoin, seconds: number) {
    if (!memecoin?.isLaunched || memecoin.liquidity.type === LiquidityType.EKUBO_NFT) return

    const extendCalldata = CallData.compile([
      memecoin.liquidity.lockPosition, // liquidity position
      seconds,
    ])

    const calls = [
      {
        contractAddress: memecoin.liquidity.lockManager,
        entrypoint: Entrypoint.EXTEND_LOCK,
        calldata: extendCalldata,
      },
    ]

    return { calls }
  }

  //
  // GET DEPLOY CALLDATA
  //

  public getDeployCalldata(data: DeployData) {
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
        entrypoint: Entrypoint.CREATE_MEMECOIN,
        calldata: constructorCalldata,
      },
    ]

    return { tokenAddress, calls }
  }

  //
  // GET LAUNCH CALLDATA
  //

  public async getEkuboLaunchCalldata(memecoin: Memecoin, data: EkuboLaunchData) {
    // get quote token current price
    const quoteTokenPrice = await getPairPrice(this.config.provider, data.quoteToken.usdcPair)

    // get the team allocation amount
    const teamAllocationFraction = data.teamAllocations.reduce((acc, { amount }) => acc.add(amount), new Fraction(0))
    const teamAllocationPercentage = new Percent(
      teamAllocationFraction.quotient,
      new Fraction(memecoin.totalSupply, decimalsScale(DECIMALS)).quotient,
    )

    // get the team allocation value in quote token at launch
    const teamAllocationQuoteAmount = new Fraction(data.startingMarketCap)
      .divide(quoteTokenPrice)
      .multiply(teamAllocationPercentage.multiply(data.fees.add(1)))
    const uin256TeamAllocationQuoteAmount = uint256.bnToUint256(
      BigInt(teamAllocationQuoteAmount.multiply(decimalsScale(data.quoteToken.decimals)).quotient.toString()),
    )

    // get initial price based on mcap and quote token price
    const initialPrice = +new Fraction(data.startingMarketCap)
      .divide(quoteTokenPrice)
      .multiply(decimalsScale(DECIMALS))
      .divide(new Fraction(memecoin.totalSupply))
      .toFixed(DECIMALS)

    // convert initial price to an Ekubo tick
    const startingTickMag = getStartingTick(initialPrice)
    const i129StartingTick = {
      mag: Math.abs(startingTickMag),
      sign: startingTickMag < 0,
    }

    // get ekubo fees
    const fees = data.fees.multiply(EKUBO_FEES_MULTIPLICATOR).quotient.toString()

    // get quote token transfer calldata to buy the team allocation
    const transferCalldata = CallData.compile([
      FACTORY_ADDRESSES[this.config.chainId], // recipient
      uin256TeamAllocationQuoteAmount, // amount
    ])

    // get initial holders informations
    const initialHolders = data.teamAllocations.map(({ address }) => address)
    const initialHoldersAmounts = data.teamAllocations.map(({ amount }) =>
      uint256.bnToUint256(BigInt(amount) * BigInt(decimalsScale(DECIMALS))),
    )

    // get launch calldata
    const launchCalldata = CallData.compile([
      memecoin.address, // memecoin address
      data.antiBotPeriod, // anti bot period in seconds
      +data.holdLimit.toFixed(1) * 100, // hold limit
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
        entrypoint: Entrypoint.TRANSFER,
        calldata: transferCalldata,
      },
      {
        contractAddress: FACTORY_ADDRESSES[this.config.chainId],
        entrypoint: Entrypoint.LAUNCH_ON_EKUBO,
        calldata: launchCalldata,
      },
    ]

    return {
      calls,
    }
  }

  public async getStandardAMMLaunchCalldata(memecoin: Memecoin, data: StandardAMMLaunchData) {
    // get quote token current price
    const quoteTokenPrice = await getPairPrice(this.config.provider, data.quoteToken.usdcPair)

    // get the team allocation percentage
    const teamAllocationFraction = data.teamAllocations.reduce((acc, { amount }) => acc.add(amount), new Fraction(0))
    const teamAllocationPercentage = new Percent(
      teamAllocationFraction.quotient,
      new Fraction(memecoin.totalSupply, decimalsScale(DECIMALS)).quotient,
    )

    // get the amount of quote token needed in the pool
    const quoteAmount = new Fraction(data.startingMarketCap)
      .divide(quoteTokenPrice)
      .multiply(new Fraction(1).subtract(teamAllocationPercentage))
    const uin256QuoteAmount = uint256.bnToUint256(BigInt(quoteAmount.multiply(decimalsScale(18)).quotient.toString()))

    // get initial holders informations
    const initialHolders = data.teamAllocations.map(({ address }) => address)
    const initialHoldersAmounts = data.teamAllocations.map(({ amount }) =>
      uint256.bnToUint256(BigInt(amount) * BigInt(decimalsScale(DECIMALS))),
    )

    // quote token approve calldata
    const approveCalldata = CallData.compile([
      FACTORY_ADDRESSES[this.config.chainId], // spender
      uin256QuoteAmount,
    ])

    // launch calldata
    const launchCalldata = CallData.compile([
      memecoin.address, // memecoin address
      data.antiBotPeriod, // anti bot period in seconds
      +data.holdLimit.toFixed(1) * 100, // hold limit
      data.quoteToken.address, // quote token
      initialHolders, // initial holders
      initialHoldersAmounts, // initial holders amounts
      uin256QuoteAmount, // quote amount
      data.liquidityLockPeriod,
    ])

    const calls = [
      {
        contractAddress: data.quoteToken.address,
        entrypoint: Entrypoint.APPROVE,
        calldata: approveCalldata,
      },
      {
        contractAddress: FACTORY_ADDRESSES[this.config.chainId],
        entrypoint: AMMS[data.amm].launchEntrypoint,
        calldata: launchCalldata,
      },
    ]

    return {
      calls,
    }
  }
}
