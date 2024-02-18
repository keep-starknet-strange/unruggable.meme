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
} from 'src/hooks/useLaunchForm'
import useMemecoin from 'src/hooks/useMemecoin'
import { useEtherPrice } from 'src/hooks/usePrice'
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

  // team allocation buyout
  const teamAllocationBuyoutAmount = new Fraction(0)

  // eth price
  const ethPrice = useEtherPrice()

  // starting tick
  const i129StartingTick = useMemo(() => {
    if (!ethPrice || !startingMcap || !memecoin) return

    // initial price in quote/MEME = mcap / eth price / total supply
    const initalPrice = +new Fraction(parseFormatedAmount(startingMcap))
      .divide(ethPrice)
      .multiply(decimalsScale(DECIMALS))
      .divide(new Fraction(memecoin.totalSupply))
      .toFixed(DECIMALS)

    const startingTickMag = getStartingTick(initalPrice)

    return {
      mag: Math.abs(startingTickMag),
      sign: startingTickMag < 0,
    }
  }, [ethPrice, startingMcap, memecoin])

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
    if (!i129StartingTick || !fees || !chainId || !hodlLimit || !memecoin?.address) return

    const approveCalldata = CallData.compile([
      FACTORY_ADDRESSES[chainId], // spender
      '0', // TODO
      '0',
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
          entrypoint: Selector.APPROVE,
          calldata: approveCalldata,
        },
        {
          contractAddress: FACTORY_ADDRESSES[chainId],
          entrypoint: Selector.LAUNCH_ON_EKUBO,
          calldata: launchCalldata,
        },
      ],
      action: 'Launch on JediSwap',
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
  ])

  return <LaunchTemplate teamAllocationPrice={teamAllocationBuyoutAmount} previous={previous} next={launch} />
}
