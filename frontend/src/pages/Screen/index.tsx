import { useCallback, useState } from 'react'
import { SecondaryButton } from 'src/components/Button'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './style.css'

// ... existing code ...

export default function ScreenPage() {
  const [tokenAddress, setTokenAddress] = useState<string>('')
  const [checkResult, setCheckResult] = useState<string | null>(null)
  const [liquidityLockDuration, setLiquidityLockDuration] = useState<number | null>(null)
  const [maxHolders, setMaxHolders] = useState<number | null>(null)
  const [maxTransactionAmount, setMaxTransactionAmount] = useState<number | null>(null)
  const [hiddenMintFunctions, setHiddenMintFunctions] = useState<boolean | null>(null)
  const [permissionsAndLimitations, setPermissionsAndLimitations] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState<boolean>(false)
  const [error, setError] = useState<string | null>(null)
  const checkSafety = useCallback(() => {
    if (!tokenAddress) {
      setError('Please enter a token address')
      return
    }
    setError(null) // reset the error
    setIsLoading(true)
    setIsLoading(true)
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
      const result = tokenAddress ? 'Success' : 'Fail'
      setCheckResult(result)

      // simulate other checks
      setLiquidityLockDuration(365) // replace with actual calculation
      setMaxHolders(1000) // replace with actual calculation
      setMaxTransactionAmount(1000000) // replace with actual calculation
      setHiddenMintFunctions(false) // replace with actual check
      setPermissionsAndLimitations('None') // replace with actual calculation
      setIsLoading(false)
    }, 2500)
  }, [tokenAddress])

  return (
    <Row className={styles.wrapper}>
      <Box className={styles.container}>
        <Box className={styles.container}>
          <Column gap="20">
            <Column gap="4">
              <Text.Body className={styles.inputLabel}>Token Address:</Text.Body>
              <input
                className={styles.inputContainer}
                value={tokenAddress}
                onChange={(e) => setTokenAddress(e.target.value)}
              />
            </Column>

            <SecondaryButton onClick={checkSafety}>Check Safety</SecondaryButton>
            {isLoading && (
              <div
                dangerouslySetInnerHTML={{
                  __html: `
                    <iframe src="https://giphy.com/embed/rHA6zm9rRSauk" width="480" height="478" frameBorder="0" class="giphy-embed" allowFullScreen></iframe>
                    <p><a href="https://giphy.com/gifs/naruto-manga-rHA6zm9rRSauk">via GIPHY</a></p>
                  `,
                }}
              />
            )}
            {error && <Text.Body className={styles.errorContainer}>{error}</Text.Body>}
            {checkResult && <Text.Body>Check Result: {checkResult}</Text.Body>}
            {checkResult === 'Fail' && (
              <div
                dangerouslySetInnerHTML={{
                  __html: `
                    <iframe src="https://giphy.com/embed/EuIPQm73w0BlpLXGq2" width="480" height="360" frameBorder="0" class="giphy-embed" allowFullScreen></iframe>
                    <p><a href="https://giphy.com/gifs/art-typography-alphabet-EuIPQm73w0BlpLXGq2">via GIPHY</a></p>
                  `,
                }}
              />
            )}
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
        </Box>
      </Box>
    </Row>
  )
}
