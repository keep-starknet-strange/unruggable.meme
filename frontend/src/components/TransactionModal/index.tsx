import { useContractWrite, useWaitForTransaction } from '@starknet-react/core'
import { useEffect, useMemo, useState } from 'react'
import { useCloseModal, useTransactionModal } from 'src/hooks/useModal'
import { useTransaction } from 'src/hooks/useTransactions'
import { InvokeTransactionDetails } from 'src/state/transaction'
import { Column, Row } from 'src/theme/components/Flex'
import * as Icons from 'src/theme/components/Icons'
import * as Text from 'src/theme/components/Text'
import { TransactionStatus } from 'starknet'

import Portal from '../common/Portal'
import Content from '../Modal/Content'
import Overlay from '../Modal/Overlay'
import Spinner from '../Spinner'
import * as styles from './style.css'

type UseWaitForTransactionResponse = Omit<ReturnType<typeof useWaitForTransaction>, 'data'> & {
  data?: { finality_status?: TransactionStatus }
}

export function TransactionModal() {
  const [currentInvokeTransactionDetails, setCurrentInvokeTransactionDetails] =
    useState<InvokeTransactionDetails | null>(null)
  const [transactionHash, setTransactionHash] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [accepted, setAccepted] = useState(false)

  // modal
  const [isOpen] = useTransactionModal()
  const close = useCloseModal()

  // starknet
  const { writeAsync } = useContractWrite({})

  // calls
  const [invokeTransactionDetails, resetTransaction] = useTransaction()

  // transaction status
  const { data } = useWaitForTransaction({
    hash: transactionHash ?? undefined,
  }) as UseWaitForTransactionResponse

  const statusComponent = useMemo(() => {
    switch (data?.finality_status) {
      // Success
      case TransactionStatus.ACCEPTED_ON_L1:
      case TransactionStatus.ACCEPTED_ON_L2:
        return (
          <>
            <Row className={styles.iconContainer({ success: true })}>
              <Icons.Checkmark width="64" height="64" />
            </Row>
            <Text.HeadlineLarge>Transaction accepted</Text.HeadlineLarge>
          </>
        )

      // Loading
      case TransactionStatus.RECEIVED:
      case undefined:
        return <Spinner />

      // Error
      default:
        setError('Transaction rejected')
    }

    return
  }, [data?.finality_status])

  // onSuccess callback
  useEffect(() => {
    if (accepted || !currentInvokeTransactionDetails?.onSuccess) return

    switch (data?.finality_status) {
      // Success
      case TransactionStatus.ACCEPTED_ON_L1:
      case TransactionStatus.ACCEPTED_ON_L2:
        setAccepted(true)
        currentInvokeTransactionDetails.onSuccess()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [accepted, data?.finality_status, currentInvokeTransactionDetails?.onSuccess])

  // error component
  const errorComponent = useMemo(() => {
    if (error) {
      return (
        <>
          <Row className={styles.iconContainer({ success: false })}>
            <Icons.Close width="64" height="64" />
          </Row>
          <Text.HeadlineLarge>Transaction rejected</Text.HeadlineLarge>
          <Text.Error>{error}</Text.Error>
        </>
      )
    }

    return
  }, [error])

  // execute transaction
  useEffect(() => {
    if (!currentInvokeTransactionDetails) return

    writeAsync({ calls: currentInvokeTransactionDetails.calls })
      .then((res) => {
        setTransactionHash(res.transaction_hash)
      })
      .catch((err) => {
        console.error(err)

        setError(err.message)
      })

    resetTransaction()
  }, [resetTransaction, currentInvokeTransactionDetails, writeAsync])

  // updating current invoke transaction details
  useEffect(() => {
    if (invokeTransactionDetails) setCurrentInvokeTransactionDetails(invokeTransactionDetails)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [!!invokeTransactionDetails])

  // clean status
  useEffect(() => {
    if (!isOpen) {
      setError(null)
      setTransactionHash(null)
      setAccepted(false)
      setCurrentInvokeTransactionDetails(null)
    }
  }, [isOpen])

  if (!isOpen) return null

  return (
    <Portal>
      <Content title={invokeTransactionDetails?.action ?? currentInvokeTransactionDetails?.action ?? ''} close={close}>
        <Column gap="24" alignItems="center">
          {errorComponent ?? statusComponent}
        </Column>
      </Content>

      <Overlay onClick={close} />
    </Portal>
  )
}
