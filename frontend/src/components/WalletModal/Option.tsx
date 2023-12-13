import { useConnect } from '@starknet-react/core'
import { Connection, L2Connection } from 'src/connections'
import Box from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './Option.css'

interface OptionProps {
  connection: Connection
  activate: () => void
}

function Option({ connection, activate }: OptionProps) {
  return (
    <Row gap="12" className={styles.option} onClick={activate}>
      <Box as="img" width="32" height="32" src={connection.getIcon?.()} />
      <Text.Body>{connection.getName()}</Text.Body>
    </Row>
  )
}

interface L2OptionProps {
  connection: L2Connection
}

export function L2Option({ connection }: L2OptionProps) {
  // wallet activation
  const { connect } = useConnect()
  const activate = () => connect({ connector: connection.connector })

  return <Option connection={connection} activate={activate} />
}
