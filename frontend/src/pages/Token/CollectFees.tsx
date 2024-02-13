import { useContractWrite } from '@starknet-react/core'
import { useCallback } from 'react'
import { PrimaryButton } from 'src/components/Button'
import { Selector } from 'src/constants/misc'
import { LaunchedMemecoin, LockPosition } from 'src/hooks/useMemecoin'
import { CallData } from 'starknet'

interface CollectFeesProps {
  memecoinInfos: LaunchedMemecoin
  liquidityLockPosition: LockPosition
}

export default function CollectFees({ memecoinInfos, liquidityLockPosition }: CollectFeesProps) {
  // starknet
  const { writeAsync } = useContractWrite({})

  const collectFees = useCallback(() => {
    const collectFeesCalldata = CallData.compile([
      memecoinInfos.address, // memecoin address
      liquidityLockPosition.owner,
    ])

    writeAsync({
      calls: [
        {
          contractAddress: memecoinInfos.launch.liquidityLockManager,
          entrypoint: Selector.WITHDRAW_FEES,
          calldata: collectFeesCalldata,
        },
      ],
    })
  }, [liquidityLockPosition.owner, memecoinInfos.address, memecoinInfos.launch.liquidityLockManager, writeAsync])

  return <PrimaryButton onClick={collectFees}>Collect fees</PrimaryButton>
}
