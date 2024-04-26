import { useContractRead, UseContractReadResult } from '@starknet-react/core'
import { compiledMulticall, MULTICALL_ADDRESSES, Entrypoint } from 'core/constants'
import { useMemo } from 'react'
import { Link } from 'react-router-dom'
import { PrimaryButton, SecondaryButton } from 'src/components/Button'
import { ImportTokenModal } from 'src/components/ImportTokenModal'
import Section from 'src/components/Section'
import useChainId from 'src/hooks/useChainId'
import { useDeploymentStore } from 'src/hooks/useDeployment'
import { useImportTokenModal } from 'src/hooks/useModal'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { CallStruct, hash } from 'starknet'

import * as styles from './style.css'
import TokenContract from './TokenContract'

export default function TokensPage() {
  const chainId = useChainId()

  // modal
  const [, toggleImportTokenModel] = useImportTokenModal()

  // deployed tokens
  const [deployedTokenContracts] = useDeploymentStore()

  const launchedStatusCallArgs = useMemo(
    () => [
      deployedTokenContracts.map(
        (tokenContract): CallStruct => ({
          to: tokenContract.address,
          selector: hash.getSelector(Entrypoint.IS_LAUNCHED),
          calldata: [],
        }),
      ),
    ],
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [deployedTokenContracts.length],
  )

  const launchedStatus = useContractRead({
    abi: compiledMulticall,
    address: chainId ? MULTICALL_ADDRESSES[chainId] : undefined,
    functionName: Entrypoint.AGGREGATE,
    watch: true,
    args: launchedStatusCallArgs,
  }) as UseContractReadResult & { data?: [bigint, [bigint][]] }

  const parsedLaunchedStatus = useMemo(
    () =>
      deployedTokenContracts.reduce<Record<string, boolean>>((acc, tokenContract, index) => {
        const status = launchedStatus.data?.[1][index]
        if (status === undefined) return acc

        acc[tokenContract.address] = !!+status
        return acc
      }, {}),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [launchedStatusCallArgs.length, launchedStatus?.data?.[0].toString()],
  )

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
              parsedLaunchedStatus[a.address] === parsedLaunchedStatus[b.address]
                ? 0
                : parsedLaunchedStatus[a.address]
                ? 1
                : -1,
            )
            .map((tokenContract) => (
              <Link key={tokenContract.address} to={`/token/${tokenContract.address}`}>
                <TokenContract tokenContract={tokenContract} launched={parsedLaunchedStatus[tokenContract.address]} />
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
