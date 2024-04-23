import { useCallback } from 'react'
import { useBoundStore } from 'src/state'
import { InvokeTransactionDetails } from 'src/state/transaction'

import { useTransactionModal } from './useModal'

export function useTransaction() {
  return useBoundStore((state) => [state.invokeTransactionDetails, state.resetTransaction] as const)
}

export function useExecuteTransaction() {
  // modal
  const [, toggleTransactionModal] = useTransactionModal()

  // calls
  const prepareTransaction = useBoundStore((state) => state.prepareTransaction)

  return useCallback(
    (invokeTransactionDetails: InvokeTransactionDetails) => {
      prepareTransaction(invokeTransactionDetails)
      toggleTransactionModal()
    },
    [prepareTransaction, toggleTransactionModal],
  )
}
