import { useAccount } from '@starknet-react/core'
import { useEffect, useMemo } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { PrimaryButton } from 'src/components/Button'
import Section from 'src/components/Section'
import { useWalletConnectModal } from 'src/hooks/useModal'
import { useExecuteTransaction } from 'src/hooks/useTransactions'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import type { Call } from 'starknet'

import * as styles from './style.css'

export default function SignTransaction() {
  const { calls } = useParams()

  const decodedCalls = useMemo(() => {
    const encodedCalls = decodeURIComponent(calls ?? '')
    let decodedCalls: Call[] = []

    try {
      decodedCalls = JSON.parse(encodedCalls)
      if (!Array.isArray(decodedCalls)) decodedCalls = []
    } catch (error) {
      //
    }

    return decodedCalls
  }, [calls])

  const [walletConnectModalShown, toggleWalletConnectModal] = useWalletConnectModal()
  const executeTransaction = useExecuteTransaction()
  const navigate = useNavigate()

  const { address } = useAccount()

  useEffect(() => {
    if (!address && !walletConnectModalShown) {
      toggleWalletConnectModal()
    }
  }, [address, walletConnectModalShown, toggleWalletConnectModal])

  const onSignClick = async () => {
    if (!address || !decodedCalls?.length) return

    executeTransaction({
      calls: decodedCalls,
      action: 'Sign Transaction',
      onSuccess: () => {
        navigate('/')
      },
    })
  }

  return (
    <Section>
      <Box className={styles.container}>
        <Column gap="24">
          <Text.HeadlineLarge>Sign Transaction</Text.HeadlineLarge>

          <Text.Body>
            You are about to sign {decodedCalls.length} calls. Please make sure to review them carefully before signing.
          </Text.Body>

          <Text.Body>
            <b>If you did not initiate this request, please do not sign.</b>
          </Text.Body>

          <PrimaryButton type="submit" large onClick={onSignClick}>
            Sign Transaction
          </PrimaryButton>
        </Column>
      </Box>
    </Section>
  )
}
