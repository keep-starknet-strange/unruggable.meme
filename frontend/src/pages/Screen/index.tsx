import { zodResolver } from '@hookform/resolvers/zod'
import { useCallback, useState } from 'react'
import { useForm } from 'react-hook-form'
import { PrimaryButton } from 'src/components/Button'
import Input from 'src/components/Input'
import Section from 'src/components/Section'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { address } from 'src/utils/zod'
import { z } from 'zod'

import * as styles from './style.css'

const schema = z.object({
  tokenAddress: address,
})

export default function ScreenPage() {
  const [checkResult, setCheckResult] = useState<string | null>(null)
  const [liquidityLockDuration, setLiquidityLockDuration] = useState<number | null>(null)
  const [maxHolders, setMaxHolders] = useState<number | null>(null)
  const [maxTransactionAmount, setMaxTransactionAmount] = useState<number | null>(null)
  const [hiddenMintFunctions, setHiddenMintFunctions] = useState<boolean | null>(null)
  const [permissionsAndLimitations, setPermissionsAndLimitations] = useState<string | null>(null)
  const [loading, setLoading] = useState<boolean>(false)
  const [error, setError] = useState<string | null>(null)

  const checkSafety = useCallback((data: z.infer<typeof schema>) => {
    if (!data.tokenAddress) {
      setError('Please enter a token address')
      return
    }
    setError(null) // reset the error
    setLoading(true)
    setCheckResult(null) // reset the result
    // reset other results
    setLiquidityLockDuration(null)
    setMaxHolders(null)
    setMaxTransactionAmount(null)
    setHiddenMintFunctions(null)
    setPermissionsAndLimitations(null)

    setTimeout(() => {
      // simulate a check operation
      // for now, we'll just check if the token address is not empty
      const result = data.tokenAddress ? 'Success' : 'Fail'
      setCheckResult(result)

      // simulate other checks
      setLiquidityLockDuration(365) // replace with actual calculation
      setMaxHolders(1000) // replace with actual calculation
      setMaxTransactionAmount(1000000) // replace with actual calculation
      setHiddenMintFunctions(false) // replace with actual check
      setPermissionsAndLimitations('None') // replace with actual calculation
      setLoading(false)
    }, 2500)
  }, [])

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<z.infer<typeof schema>>({
    resolver: zodResolver(schema),
  })

  return (
    <Section>
      <Box className={styles.container}>
        <Column gap="32">
          <Box as="form" onSubmit={handleSubmit(checkSafety)}>
            <Column gap="8">
              <Text.Body className={styles.inputLabel}>Token Address</Text.Body>

              <Input placeholder="0x000000000000000000" {...register('tokenAddress')} />

              <Box className={styles.errorContainer}>
                {errors.tokenAddress?.message ? <Text.Error>{errors.tokenAddress.message}</Text.Error> : null}
              </Box>

              <PrimaryButton type="submit" disabled={loading}>
                {loading ? 'Loading...' : 'Check Safety'}
              </PrimaryButton>
            </Column>
          </Box>

          <Column gap="20">
            {error && <Text.Body className={styles.errorContainer}>{error}</Text.Body>}
            {checkResult && <Text.Body>Check Result: {checkResult}</Text.Body>}
            {liquidityLockDuration !== null && (
              <Text.Body>
                Liquidity Lock Duration:
                <b> {liquidityLockDuration} days</b>
              </Text.Body>
            )}
            {maxHolders !== null && <Text.Body>Maximum Number of Holders: {maxHolders}</Text.Body>}
            {maxTransactionAmount !== null && (
              <Text.Body>
                Maximum Transaction Amount:
                <b> {maxTransactionAmount}</b>
              </Text.Body>
            )}
            {hiddenMintFunctions !== null && (
              <Text.Body>
                Hidden Mint Functions:
                <b> {hiddenMintFunctions ? 'Yes' : '❌No'}</b>
              </Text.Body>
            )}
            {permissionsAndLimitations !== null && (
              <Text.Body>
                Permissions and Limitations:
                <b> {permissionsAndLimitations}</b>
              </Text.Body>
            )}
          </Column>
        </Column>
      </Box>
    </Section>
  )
}
