import { Fraction } from '@uniswap/sdk-core'
import { useCallback, useMemo } from 'react'
import { PrimaryButton } from 'src/components/Button'
import { LiquidityType, Selector } from 'src/constants/misc'
import useEkuboFees from 'src/hooks/useEkuboFees'
import useMemecoin from 'src/hooks/useMemecoin'
import useQuoteToken from 'src/hooks/useQuote'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { formatCurrenyAmount } from 'src/utils/amount'
import { CallData } from 'starknet'

import * as styles from './style.css'

export default function CollectFees() {
  // starknet
  const executeTransaction = useExecuteTransaction()

  // memecoin
  const { data: memecoin, refresh: refreshMemecoin } = useMemecoin()

  // quote token
  const quoteToken = useQuoteToken(memecoin?.isLaunched ? memecoin.liquidity.quoteToken : undefined)

  // feesToCollect
  const feesToCollect = useEkuboFees()

  // collect fees
  const collectFees = useCallback(() => {
    if (!memecoin?.isLaunched || memecoin.liquidity.type !== LiquidityType.NFT) return

    const collectFeesCalldata = CallData.compile([
      memecoin.liquidity.ekuboId, // ekubo pool id
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
      onSuccess: refreshMemecoin,
    })
  }, [memecoin, executeTransaction, refreshMemecoin])

  // can collect
  const canCollect = useMemo(() => feesToCollect?.greaterThan(new Fraction(0)) ?? false, [feesToCollect])

  return (
    <Column gap="32">
      <Box className={styles.card}>
        <Column gap="8" alignItems="flex-start">
          <Text.Small>Fees to collect:</Text.Small>
          <Text.HeadlineMedium color={canCollect ? 'accent' : feesToCollect ? 'text1' : 'text2'} whiteSpace="nowrap">
            {feesToCollect && quoteToken
              ? `${formatCurrenyAmount(feesToCollect, { fixed: 4, significant: 2 })} ${quoteToken.symbol}`
              : 'Loading'}
          </Text.HeadlineMedium>
        </Column>
      </Box>

      <PrimaryButton onClick={canCollect ? collectFees : undefined} disabled={!canCollect}>
        {canCollect ? 'Collect fees' : 'Nothing to collect'}
      </PrimaryButton>
    </Column>
  )
}
