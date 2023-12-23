import { Percent } from '@uniswap/sdk-core'
import { useMemo } from 'react'
import { TokenContract as TokenContractType } from 'src/state/contracts'
import Box, { BoxProps } from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { encode } from 'starknet'

import * as styles from './TokenContract.css'

interface TokenContractProps extends BoxProps {
  tokenContract: TokenContractType
}

export default function TokenContract({ tokenContract, ...props }: TokenContractProps) {
  const teamAllocationPercentage = useMemo(
    () => new Percent(tokenContract.teamAllocation, tokenContract.maxSupply).toFixed(),
    [tokenContract.teamAllocation, tokenContract.maxSupply]
  )

  const backgroundPosition = useMemo(() => {
    const seed = +encode.addHexPrefix(tokenContract.address.slice(-6))
    return `${seed % 100}% ${Math.round(seed / 100) % 70}%`
  }, [tokenContract.address])

  return (
    <Box
      className={styles.tokenContractContainer}
      key={tokenContract.address}
      style={{ backgroundPosition }}
      {...props}
    >
      <Column gap="24">
        <Row justifyContent="space-between" gap="8">
          <Row gap="12" alignItems="baseline" minWidth="0" flex="1">
            <Text.HeadlineMedium className={styles.tokenName}>{tokenContract.name}</Text.HeadlineMedium>
            <Text.Body color="text2">${tokenContract.symbol}</Text.Body>
          </Row>

          <Text.Custom className={styles.launchStatus({ launched: tokenContract.launched })}>
            {tokenContract.launched ? 'Launched' : 'Not launched'}
          </Text.Custom>
        </Row>

        <Row gap="8">
          <Text.Body>Team allocation:</Text.Body>
          <Text.HeadlineSmall color={+teamAllocationPercentage ? 'text1' : 'accent'}>
            {teamAllocationPercentage}%
          </Text.HeadlineSmall>
        </Row>
      </Column>
    </Box>
  )
}
