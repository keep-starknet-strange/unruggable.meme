import { useCallback } from 'react'
import { PrimaryButton } from 'src/components/Button'
import { LiquidityType, Selector } from 'src/constants/misc'
import useMemecoin from 'src/hooks/useMemecoin'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import { CallData } from 'starknet'

export default function CollectFees() {
  // starknet
  const executeTransaction = useExecuteTransaction()

  // memecoin
  const { data: memecoin } = useMemecoin()

  const collectFees = useCallback(() => {
    if (!memecoin?.isLaunched || memecoin.liquidity.type !== LiquidityType.NFT) return

    const collectFeesCalldata = CallData.compile([
      memecoin.address, // memecoin address
      memecoin.liquidity.owner,
    ])

    executeTransaction({
      calls: [
        {
          contractAddress: memecoin.liquidity.lockManager,
          entrypoint: Selector.WITHDRAW_FEES,
          calldata: collectFeesCalldata,
        },
      ],
      action: 'Collect fees',
    })
  }, [memecoin, executeTransaction])

  return <PrimaryButton onClick={collectFees}>Collect fees</PrimaryButton>
}
