import { Fraction } from '@uniswap/sdk-core'
import moment from 'moment'
import { useCallback, useMemo } from 'react'
import { ETH_ADDRESS, FACTORY_ADDRESSES } from 'src/constants/contracts'
import { DECIMALS, LIQUIDITY_LOCK_FOREVER_TIMESTAMP, MAX_LIQUIDITY_LOCK_PERIOD, Selector } from 'src/constants/misc'
import useChainId from 'src/hooks/useChainId'
import {
  useHodlLimitForm,
  useJediswapLiquidityForm,
  useLiquidityForm,
  useResetLaunchForm,
  useTeamAllocation,
  useTeamAllocationTotalPercentage,
} from 'src/hooks/useLaunchForm'
import useMemecoin from 'src/hooks/useMemecoin'
import { useEtherPrice } from 'src/hooks/usePrice'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import { parseFormatedAmount } from 'src/utils/amount'
import { decimalsScale } from 'src/utils/decimalScale'
import { CallData, uint256 } from 'starknet'

import { LastFormPageProps } from '../common'
import LaunchTemplate from './template'

export default function JediswapLaunch({ previous }: LastFormPageProps) {
  // form data
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { startingMcap } = useLiquidityForm()
  const { liquidityLockPeriod } = useJediswapLiquidityForm()
  const { teamAllocation } = useTeamAllocation()
  const resetLaunchForm = useResetLaunchForm()

  // memecoin
  const { data: memecoin, refresh: refreshMemecoin } = useMemecoin()

  // eth price
  const ethPrice = useEtherPrice()

  // team allocation
  const teamAllocationTotalPercentage = useTeamAllocationTotalPercentage(memecoin?.totalSupply)

  // quote amount
  const quoteAmount = useMemo(() => {
    if (!ethPrice || !startingMcap || !teamAllocationTotalPercentage) return

    // mcap / eth_price * (1 - team_allocation / total_supply)
    return new Fraction(parseFormatedAmount(startingMcap))
      .divide(ethPrice)
      .multiply(new Fraction(1).subtract(teamAllocationTotalPercentage))
  }, [teamAllocationTotalPercentage, startingMcap, ethPrice])

  // starknet
  const chainId = useChainId()

  // transaction
  const executeTransaction = useExecuteTransaction()

  // launch
  const launch = useCallback(() => {
    if (!quoteAmount || !chainId || !hodlLimit || !memecoin?.address) return

    const uin256QuoteAmount = uint256.bnToUint256(
      BigInt(quoteAmount.multiply(decimalsScale(DECIMALS)).quotient.toString())
    )

    const approveCalldata = CallData.compile([
      FACTORY_ADDRESSES[chainId], // spender
      uin256QuoteAmount,
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
      ETH_ADDRESS, // quote token
      initalHolders, // initial holders
      initalHoldersAmounts, // intial holders amounts
      uin256QuoteAmount, // quote amount
      liquidityLockPeriod === MAX_LIQUIDITY_LOCK_PERIOD // liquidity lock until
        ? LIQUIDITY_LOCK_FOREVER_TIMESTAMP
        : moment().add(moment.duration(liquidityLockPeriod, 'months')).unix(),
    ])

    executeTransaction({
      calls: [
        {
          contractAddress: ETH_ADDRESS,
          entrypoint: Selector.APPROVE,
          calldata: approveCalldata,
        },
        {
          contractAddress: FACTORY_ADDRESSES[chainId],
          entrypoint: Selector.LAUNCH_ON_JEDISWAP,
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
    quoteAmount,
    chainId,
    hodlLimit,
    memecoin?.address,
    teamAllocation,
    antiBotPeriod,
    liquidityLockPeriod,
    executeTransaction,
    refreshMemecoin,
    resetLaunchForm,
  ])

  return <LaunchTemplate liquidityPrice={quoteAmount} previous={previous} next={launch} />
}
