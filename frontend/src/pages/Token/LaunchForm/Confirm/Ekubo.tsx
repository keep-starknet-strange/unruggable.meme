import { Fraction } from '@uniswap/sdk-core'
import { useCallback, useMemo } from 'react'
import { FACTORY_ADDRESSES } from 'src/constants/contracts'
import { DECIMALS, EKUBO_BOUND, EKUBO_FEES_MULTIPLICATOR, EKUBO_TICK_SPACING, Selector } from 'src/constants/misc'
import useChainId from 'src/hooks/useChainId'
import {
  useEkuboLiquidityForm,
  useHodlLimitForm,
  useLiquidityForm,
  useResetLaunchForm,
  useTeamAllocation,
  useTeamAllocationTotalPercentage,
} from 'src/hooks/useLaunchForm'
import useMemecoin from 'src/hooks/useMemecoin'
import { useQuoteTokenPrice } from 'src/hooks/usePrice'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import { parseFormatedAmount, parseFormatedPercentage } from 'src/utils/amount'
import { decimalsScale } from 'src/utils/decimals'
import { getStartingTick } from 'src/utils/ekubo'
import { CallData, uint256 } from 'starknet'

import { LastFormPageProps } from '../common'
import LaunchTemplate from './template'

export default function EkuboLaunch({ previous }: LastFormPageProps) {
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { startingMcap, quoteTokenAddress } = useLiquidityForm()
  const { ekuboFees } = useEkuboLiquidityForm()
  const { teamAllocation } = useTeamAllocation()
  const resetLaunchForm = useResetLaunchForm()

  // memecoin
  const { data: memecoin, refresh: refreshMemecoin } = useMemecoin()

  // quote token price
  const quoteTokenPrice = useQuoteTokenPrice(quoteTokenAddress)

  // team allocation
  const teamAllocationTotalPercentage = useTeamAllocationTotalPercentage(memecoin?.totalSupply)

  // team allocation quote amount
  const teamAllocationQuoteAmount = useMemo(() => {
    if (!quoteTokenPrice || !startingMcap || !teamAllocationTotalPercentage || !ekuboFees) return

    // mcap / quote_token_price * (team_allocation / total_supply * (1 + ekuboFees))
    return new Fraction(parseFormatedAmount(startingMcap))
      .divide(quoteTokenPrice)
      .multiply(teamAllocationTotalPercentage.multiply(parseFormatedPercentage(ekuboFees).add(1)))
  }, [quoteTokenPrice, startingMcap, teamAllocationTotalPercentage, ekuboFees])

  // starting tick
  const i129StartingTick = useMemo(() => {
    if (!quoteTokenPrice || !startingMcap || !memecoin) return

    // initial price in quote/MEME = mcap / quote token price / total supply
    const initalPrice = +new Fraction(parseFormatedAmount(startingMcap))
      .divide(quoteTokenPrice)
      .multiply(decimalsScale(DECIMALS))
      .divide(new Fraction(memecoin.totalSupply))
      .toFixed(DECIMALS)

    const startingTickMag = getStartingTick(initalPrice)

    return {
      mag: Math.abs(startingTickMag),
      sign: startingTickMag < 0,
    }
  }, [quoteTokenPrice, startingMcap, memecoin])

  // fees
  const fees = useMemo(() => {
    if (!ekuboFees) return

    return parseFormatedPercentage(ekuboFees).multiply(EKUBO_FEES_MULTIPLICATOR).quotient.toString()
  }, [ekuboFees])

  // starknet
  const chainId = useChainId()

  // transaction
  const executeTransaction = useExecuteTransaction()

  // launch
  const launch = useCallback(() => {
    if (!i129StartingTick || !fees || !chainId || !hodlLimit || !memecoin?.address || !teamAllocationQuoteAmount) return

    const uin256TeamAllocationQuoteAmount = uint256.bnToUint256(
      BigInt(teamAllocationQuoteAmount.multiply(decimalsScale(DECIMALS)).quotient.toString())
    )

    const transferCalldata = CallData.compile([
      FACTORY_ADDRESSES[chainId], // recipient
      uin256TeamAllocationQuoteAmount, // amount
    ])

    // team allocation
    const initalHolders = Object.values(teamAllocation)
      .filter(Boolean)
      .map((holder) => holder.address)
    const initalHoldersAmounts = Object.values(teamAllocation)
      .filter(Boolean)
      .map((holder) => uint256.bnToUint256(BigInt(parseFormatedAmount(holder.amount)) * BigInt(decimalsScale(18))))

    // prepare calldata
    const launchCalldata = CallData.compile([
      memecoin.address, // memecoin address
      antiBotPeriod * 60, // anti bot period in seconds
      +hodlLimit * 100, // hodl limit
      quoteTokenAddress, // quote token
      initalHolders, // initial holders
      initalHoldersAmounts, // intial holders amounts

      fees, // ekubo fees
      EKUBO_TICK_SPACING, // tick spacing
      i129StartingTick, // starting tick
      EKUBO_BOUND, // bound,
    ])

    executeTransaction({
      calls: [
        {
          contractAddress: quoteTokenAddress,
          entrypoint: Selector.TRANSFER,
          calldata: transferCalldata,
        },
        {
          contractAddress: FACTORY_ADDRESSES[chainId],
          entrypoint: Selector.LAUNCH_ON_EKUBO,
          calldata: launchCalldata,
        },
      ],
      action: 'Launch on Ekubo',
      onSuccess: () => {
        resetLaunchForm()
        refreshMemecoin()
      },
    })
  }, [
    antiBotPeriod,
    chainId,
    executeTransaction,
    fees,
    hodlLimit,
    i129StartingTick,
    memecoin?.address,
    quoteTokenAddress,
    refreshMemecoin,
    resetLaunchForm,
    teamAllocation,
    teamAllocationQuoteAmount,
  ])

  return <LaunchTemplate teamAllocationPrice={teamAllocationQuoteAmount} previous={previous} next={launch} />
}
