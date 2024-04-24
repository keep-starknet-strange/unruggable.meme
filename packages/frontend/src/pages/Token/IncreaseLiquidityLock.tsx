import {
  LIQUIDITY_LOCK_FOREVER_TIMESTAMP,
  LIQUIDITY_LOCK_INCREASE_STEP,
  LiquidityType,
  MAX_LIQUIDITY_LOCK_INCREASE,
  MIN_LIQUIDITY_LOCK_INCREASE,
} from 'core/constants'
import { useFactory } from 'hooks'
import moment from 'moment'
import { useCallback, useMemo, useState } from 'react'
import { useParams } from 'react-router-dom'
import { PrimaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import Slider from 'src/components/Slider'
import { FOREVER } from 'src/constants/misc'
import useMemecoin from 'src/hooks/useMemecoin'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { parseMonthsDuration } from 'src/utils/moment'

export default function IncreaseLiquidityLock() {
  const [liquidityLockIncrease, setLiquidityLockIncrease] = useState(MAX_LIQUIDITY_LOCK_INCREASE)

  // parsed increase
  const parsedLiquidityLockIncrease = useMemo(
    () =>
      liquidityLockIncrease === MAX_LIQUIDITY_LOCK_INCREASE
        ? FOREVER
        : parseMonthsDuration(moment.duration(liquidityLockIncrease, 'months')),
    [liquidityLockIncrease],
  )

  // memecoin
  const { address: tokenAddress } = useParams()
  const { data: memecoin, refresh: refreshMemecoin } = useMemecoin(tokenAddress)

  // sdk factory
  const sdkFactory = useFactory()

  // transaction
  const executeTransaction = useExecuteTransaction()

  // increase tx
  const increaseLiquidityLock = useCallback(() => {
    // the only supported AMM with supported liquidity lock increase is Jediswap.
    // No need for a better way to handle that atm.
    if (!memecoin?.isLaunched || memecoin.liquidity.type === LiquidityType.EKUBO_NFT) return

    const calldata = sdkFactory.getExtendLiquidityLockCalldata(
      memecoin,
      liquidityLockIncrease === MAX_LIQUIDITY_LOCK_INCREASE // liquidity lock until
        ? LIQUIDITY_LOCK_FOREVER_TIMESTAMP
        : moment.duration(liquidityLockIncrease, 'months').asSeconds() + memecoin.liquidity.unlockTime,
    )
    if (!calldata) return

    // send tx
    executeTransaction({
      calls: calldata.calls,
      action: 'Increase liquidity lock',
      onSuccess: refreshMemecoin,
    })
  }, [sdkFactory, executeTransaction, liquidityLockIncrease, memecoin, refreshMemecoin])

  return (
    <>
      <Column gap="8">
        <Text.HeadlineSmall>Increase liquidity lock for</Text.HeadlineSmall>
        <Slider
          value={liquidityLockIncrease}
          min={MIN_LIQUIDITY_LOCK_INCREASE}
          step={LIQUIDITY_LOCK_INCREASE_STEP}
          max={MAX_LIQUIDITY_LOCK_INCREASE}
          onSlidingChange={setLiquidityLockIncrease}
          addon={<Input value={parsedLiquidityLockIncrease} />}
        />
      </Column>

      <PrimaryButton onClick={increaseLiquidityLock}>Increase liquidity lock</PrimaryButton>
    </>
  )
}
