import { Connector, useConnect } from '@starknet-react/core'
import Box from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './Option.css'

interface OptionProps {
  connection: Connector
  activate: () => void
}

function Option({ connection, activate }: OptionProps) {
  const icon = connection.icon.dark
  const isSvg = icon?.startsWith('<svg')

  return (
    <Row gap="12" className={styles.option} onClick={activate}>
      {isSvg ? (
        <Box width="32" height="32" dangerouslySetInnerHTML={{ __html: icon ?? '' }} /> /* display svg */
      ) : (
        <Box as="img" width="32" height="32" src={connection.icon.dark} />
      )}
      <Text.Body>{connection.name}</Text.Body>
    </Row>
  )
}

interface L2OptionProps {
  connection: Connector
}

export function L2Option({ connection }: L2OptionProps) {
  // wallet activation
  const { connect } = useConnect()
  const activate = () => connect({ connector: connection })

  return <Option connection={connection} activate={activate} />
}
