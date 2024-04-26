import { useMemecoins } from 'hooks'
import { useMemo } from 'react'
import { Link } from 'react-router-dom'
import { PrimaryButton, SecondaryButton } from 'src/components/Button'
import { ImportTokenModal } from 'src/components/ImportTokenModal'
import Section from 'src/components/Section'
import { useDeploymentStore } from 'src/hooks/useDeployment'
import { useImportTokenModal } from 'src/hooks/useModal'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './style.css'
import TokenContract from './TokenContract'

export default function TokensPage() {
  // modal
  const [, toggleImportTokenModel] = useImportTokenModal()

  // deployed tokens
  const [deployedTokenContracts] = useDeploymentStore()

  const deployedMemecoins = useMemecoins({
    addresses: deployedTokenContracts.map((tokenContract) => tokenContract.address),
  })

  const launchedStatuses = useMemo(() => {
    return deployedMemecoins.reduce<Record<string, boolean>>((acc, status) => {
      if (!status.isLoading && status.data) {
        acc[status.data.address] = status.data.isLaunched
      }

      return acc
    }, {})
  }, [deployedMemecoins])

  return (
    <>
      <Section>
        <Column className={styles.container}>
          <Box className={styles.headerContainer}>
            <Text.HeadlineMedium>Your deployed tokens</Text.HeadlineMedium>

            <Row gap="16">
              <SecondaryButton onClick={toggleImportTokenModel}>Import a token</SecondaryButton>

              <Link to="/deploy">
                <PrimaryButton>Deploy a token</PrimaryButton>
              </Link>
            </Row>
          </Box>

          {[...deployedTokenContracts]
            .sort((a, b) =>
              launchedStatuses[a.address] === launchedStatuses[b.address] ? 0 : launchedStatuses[a.address] ? 1 : -1,
            )
            .map((tokenContract) => (
              <Link key={tokenContract.address} to={`/token/${tokenContract.address}`}>
                <TokenContract tokenContract={tokenContract} launched={launchedStatuses[tokenContract.address]} />
              </Link>
            ))}

          {!deployedTokenContracts.length && (
            <Box className={styles.noTokensContainer}>
              <Text.Body textAlign="center">No tokens found.</Text.Body>
            </Box>
          )}
        </Column>
      </Section>

      <ImportTokenModal save />
    </>
  )
}
