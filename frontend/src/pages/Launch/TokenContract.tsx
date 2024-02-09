import { useMemo } from 'react'
import { TokenContract as TokenContractType } from 'src/state/contracts'
import Box, { BoxProps } from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import { encode } from 'starknet'

import * as styles from './TokenContract.css'

interface TokenContractProps extends BoxProps {
  tokenContract: TokenContractType
  launched?: boolean
}

export default function TokenContract({ tokenContract, launched, ...props }: TokenContractProps) {
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

          {launched !== undefined && (
            <Text.Custom className={styles.launchStatus({ launched })}>
              {launched ? 'Launched' : 'Not launched'}
            </Text.Custom>
          )}
        </Row>
      </Column>
    </Box>
  )
}
