import { useCallback } from 'react'
import { PrimaryButton } from 'src/components/Button'
import { Selector } from 'src/constants/misc'
import { LaunchedMemecoin, LockPosition } from 'src/hooks/useMemecoin'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import { CallData } from 'starknet'

interface CollectFeesProps {
  memecoinInfos: LaunchedMemecoin
  liquidityLockPosition: LockPosition
}

export default function CollectFees({ memecoinInfos, liquidityLockPosition }: CollectFeesProps) {
  // starknet
  const executeTransaction = useExecuteTransaction()

  const collectFees = useCallback(() => {
    const collectFeesCalldata = CallData.compile([
      memecoinInfos.address, // memecoin address
      liquidityLockPosition.owner,
    ])

    executeTransaction({
      calls: [
        {
          contractAddress: memecoinInfos.launch.liquidityLockManager,
          entrypoint: Selector.WITHDRAW_FEES,
          calldata: collectFeesCalldata,
        },
      ],
      action: 'Collect fees',
    })
  }, [
    liquidityLockPosition.owner,
    memecoinInfos.address,
    memecoinInfos.launch.liquidityLockManager,
    executeTransaction,
  ])

  return <PrimaryButton onClick={collectFees}>Collect fees</PrimaryButton>
}
