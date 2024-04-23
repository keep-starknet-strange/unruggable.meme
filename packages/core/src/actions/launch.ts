import { Fraction, Percent } from '@uniswap/sdk-core'
import { CallData, uint256 } from 'starknet'

import {
  AmmInfos,
  DECIMALS,
  EKUBO_BOUND,
  EKUBO_FEES_MULTIPLICATOR,
  EKUBO_TICK_SPACING,
  FACTORY_ADDRESSES,
  Selector,
} from '../constants'
import { FactoryConfig } from '../factory'
import { EkuboLaunchData, Memecoin, StandardAMMLaunchData } from '../types'
import { getStartingTick } from '../utils/ekubo'
import { decimalsScale } from '../utils/helpers'
import { getPairPrice } from './token'

export async function getEkuboLaunchCalldata(config: FactoryConfig, memecoin: Memecoin, data: EkuboLaunchData) {
  const quoteTokenPrice = await getPairPrice(config, data.quoteToken.usdcPair)

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
    FACTORY_ADDRESSES[config.chainId], // recipient
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
      contractAddress: FACTORY_ADDRESSES[config.chainId],
      entrypoint: Selector.LAUNCH_ON_EKUBO,
      calldata: launchCalldata,
    },
  ]

  return {
    calls,
  }
}

export async function getStandardAMMLaunchCalldata(
  config: FactoryConfig,
  memecoin: Memecoin,
  data: StandardAMMLaunchData,
) {
  const quoteTokenPrice = await getPairPrice(config, data.quoteToken.usdcPair)

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
    FACTORY_ADDRESSES[config.chainId], // spender
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
      contractAddress: FACTORY_ADDRESSES[config.chainId],
      entrypoint: AmmInfos[data.amm].launchEntrypoint,
      calldata: launchCalldata,
    },
  ]

  return {
    calls,
  }
}
