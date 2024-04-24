import { Fraction } from '@uniswap/sdk-core'
import { AMM } from 'core/constants'
import { useFactory, useQuoteToken, useQuoteTokenPrice } from 'hooks'
import { useCallback, useMemo } from 'react'
import { useParams } from 'react-router-dom'
import {
  useEkuboLiquidityForm,
  useHodlLimitForm,
  useLiquidityForm,
  useResetLaunchForm,
  useTeamAllocation,
  useTeamAllocationTotalPercentage,
} from 'src/hooks/useLaunchForm'
import useMemecoin from 'src/hooks/useMemecoin'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import { parseFormatedAmount, parseFormatedPercentage } from 'src/utils/amount'

import { LastFormPageProps } from '../common'
import LaunchTemplate from './template'

export default function EkuboLaunch({ previous }: LastFormPageProps) {
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { startingMcap, quoteTokenAddress } = useLiquidityForm()
  const { ekuboFees } = useEkuboLiquidityForm()
  const { teamAllocation } = useTeamAllocation()
  const resetLaunchForm = useResetLaunchForm()

  // memecoin
  const { address: tokenAddress } = useParams()
  const { data: memecoin, refresh: refreshMemecoin } = useMemecoin(tokenAddress)

  // sdk factory
  const sdkFactory = useFactory()

  // quote token
  const quoteToken = useQuoteToken(quoteTokenAddress)
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

  // transaction
  const executeTransaction = useExecuteTransaction()

  // launch
  const launch = useCallback(async () => {
    if (!memecoin || !startingMcap || !quoteToken || !hodlLimit || !ekuboFees) return

    // Sort by index and map to address and parsed amount
    const teamAllocations = Object.entries(teamAllocation)
      .sort(([a], [b]) => +a - +b)
      .map(([, holder]) => ({
        address: holder.address,
        amount: parseFormatedAmount(holder.amount),
      }))

    const { calls } = await sdkFactory.getEkuboLaunchCalldata(memecoin, {
      amm: AMM.EKUBO,
      antiBotPeriod: antiBotPeriod * 60,
      fees: parseFormatedPercentage(ekuboFees),
      holdLimit: +hodlLimit * 100,
      quoteToken,
      startingMarketCap: parseFormatedAmount(startingMcap),
      teamAllocations,
    })

    executeTransaction({
      calls,
      action: 'Launch on Ekubo',
      onSuccess: () => {
        resetLaunchForm()
        refreshMemecoin()
      },
    })
  }, [
    memecoin,
    startingMcap,
    quoteToken,
    hodlLimit,
    ekuboFees,
    teamAllocation,
    antiBotPeriod,
    sdkFactory,
    executeTransaction,
    resetLaunchForm,
    refreshMemecoin,
  ])

  return <LaunchTemplate teamAllocationPrice={teamAllocationQuoteAmount} previous={previous} next={launch} />
}
