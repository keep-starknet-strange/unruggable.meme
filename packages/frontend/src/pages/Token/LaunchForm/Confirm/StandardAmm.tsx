import { Fraction } from '@uniswap/sdk-core'
import {
  AMM,
  LIQUIDITY_LOCK_FOREVER_TIMESTAMP,
  MAX_LIQUIDITY_LOCK_PERIOD,
  STARKNET_MAX_BLOCK_TIME,
} from 'core/constants'
import { useFactory, useQuoteToken, useQuoteTokenPrice } from 'hooks'
import moment from 'moment'
import { useCallback, useMemo } from 'react'
import { useParams } from 'react-router-dom'
import {
  useHodlLimitForm,
  useLiquidityForm,
  useResetLaunchForm,
  useStandardAmmLiquidityForm,
  useTeamAllocation,
  useTeamAllocationTotalPercentage,
} from 'src/hooks/useLaunchForm'
import useMemecoin from 'src/hooks/useMemecoin'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import { parseFormatedAmount } from 'src/utils/amount'

import { LastFormPageProps } from '../common'
import LaunchTemplate from './template'

interface StarndardAmmLaunchProps extends LastFormPageProps {
  amm: AMM.JEDISWAP | AMM.STARKDEFI
}

export default function StarndardAmmLaunch({ previous, amm }: StarndardAmmLaunchProps) {
  // form data
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { startingMcap, quoteTokenAddress } = useLiquidityForm()
  const { liquidityLockPeriod } = useStandardAmmLiquidityForm()
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

  // quote amount
  const quoteAmount = useMemo(() => {
    if (!quoteTokenPrice || !startingMcap || !teamAllocationTotalPercentage) return

    // mcap / quote_token_price * (1 - team_allocation / total_supply)
    return new Fraction(parseFormatedAmount(startingMcap))
      .divide(quoteTokenPrice)
      .multiply(new Fraction(1).subtract(teamAllocationTotalPercentage))
  }, [teamAllocationTotalPercentage, startingMcap, quoteTokenPrice])

  // transaction
  const executeTransaction = useExecuteTransaction()

  // launch
  const launch = useCallback(async () => {
    if (!memecoin || !startingMcap || !quoteToken || !hodlLimit) return

    // Sort by index and map to address and parsed amount
    const teamAllocations = Object.entries(teamAllocation)
      .sort(([a], [b]) => +a - +b)
      .map(([, holder]) => ({
        address: holder.address,
        amount: parseFormatedAmount(holder.amount),
      }))

    const { calls } = await sdkFactory.getStandardAMMLaunchCalldata(memecoin, {
      amm,
      antiBotPeriod: antiBotPeriod * 60,
      holdLimit: +hodlLimit * 100,
      quoteToken,
      startingMarketCap: parseFormatedAmount(startingMcap),
      teamAllocations,
      liquidityLockPeriod:
        liquidityLockPeriod === MAX_LIQUIDITY_LOCK_PERIOD // liquidity lock until
          ? LIQUIDITY_LOCK_FOREVER_TIMESTAMP
          : moment().add(moment.duration(liquidityLockPeriod, 'months')).unix() + STARKNET_MAX_BLOCK_TIME,
    })

    executeTransaction({
      calls,
      action: `Launch on ${amm}`,
      onSuccess: () => {
        resetLaunchForm()
        refreshMemecoin()
      },
    })
  }, [
    amm,
    memecoin,
    startingMcap,
    quoteToken,
    hodlLimit,
    teamAllocation,
    antiBotPeriod,
    liquidityLockPeriod,
    sdkFactory,
    executeTransaction,
    resetLaunchForm,
    refreshMemecoin,
  ])

  return <LaunchTemplate liquidityPrice={quoteAmount} previous={previous} next={launch} />
}
