import { Fraction } from '@uniswap/sdk-core'
import moment from 'moment'
import { useCallback, useMemo } from 'react'
import { AMM } from 'src/constants/AMMs'
import { FACTORY_ADDRESSES } from 'src/constants/contracts'
import {
  DECIMALS,
  LIQUIDITY_LOCK_FOREVER_TIMESTAMP,
  MAX_LIQUIDITY_LOCK_PERIOD,
  Selector,
  STARKNET_MAX_BLOCK_TIME,
} from 'src/constants/misc'
import useChainId from 'src/hooks/useChainId'
import {
  useHodlLimitForm,
  useLiquidityForm,
  useResetLaunchForm,
  useStandardAmmLiquidityForm,
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

export default function StarndardAmmLaunch({ previous, amm }: Readonly<LastFormPageProps & { amm: AMM }>) {
  // form data
  const { hodlLimit, antiBotPeriod } = useHodlLimitForm()
  const { startingMcap, quoteTokenAddress } = useLiquidityForm()
  const { liquidityLockPeriod } = useStandardAmmLiquidityForm()
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

    const ammOptions: {
      entrypoint: Selector
      action: string
    } = {
      entrypoint: Selector.LAUNCH_ON_JEDISWAP,
      action: 'Launch on JediSwap',
    }

    switch (amm) {
      case AMM.JEDISWAP:
        ammOptions.entrypoint = Selector.LAUNCH_ON_JEDISWAP
        ammOptions.action = 'Launch on JediSwap'
        break
      case AMM.STARKDEFI:
        ammOptions.entrypoint = Selector.LAUNCH_ON_STARKDEFI
        ammOptions.action = 'Launch on StarkDeFi'
        break
    }

    // prepare calldata
    const launchCalldata = CallData.compile([
      memecoin.address, // memecoin address
      antiBotPeriod * 60, // anti bot period in seconds
      +hodlLimit * 100, // hodl limit
      quoteTokenAddress, // quote token
      initalHolders, // initial holders
      initalHoldersAmounts, // intial holders amounts
      uin256QuoteAmount, // quote amount
      liquidityLockPeriod === MAX_LIQUIDITY_LOCK_PERIOD // liquidity lock until
        ? LIQUIDITY_LOCK_FOREVER_TIMESTAMP
        : moment().add(moment.duration(liquidityLockPeriod, 'months')).unix() + STARKNET_MAX_BLOCK_TIME,
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
          entrypoint: ammOptions.entrypoint,
          calldata: launchCalldata,
        },
      ],
      action: ammOptions.action,
      onSuccess: () => {
        resetLaunchForm()
        refreshMemecoin()
      },
    })
  }, [
    amm,
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
    quoteTokenAddress,
  ])

  return <LaunchTemplate liquidityPrice={quoteAmount} previous={previous} next={launch} />
}
