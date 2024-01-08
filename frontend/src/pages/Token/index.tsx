import { useEffect, useMemo } from 'react'
import { useMatch } from 'react-router-dom'
import Section from 'src/components/Section'
import { useMemecoinInfos } from 'src/hooks/useMemecoin'
import Box from 'src/theme/components/Box'
import * as Text from 'src/theme/components/Text'
import { getChecksumAddress } from 'starknet'

import * as styles from './styles.css'

export default function TokenPage() {
  const match = useMatch('/token/:address')
  const collectionAddress = useMemo(() => {
    if (match?.params.address) {
      return getChecksumAddress(match?.params.address)
    } else {
      return null
    }
  }, [match?.params.address])

  const [{ data: memecoinInfos, error, indexing }, getMemecoinInfos] = useMemecoinInfos()

  useEffect(() => {
    if (collectionAddress) {
      getMemecoinInfos(collectionAddress)
    }
  }, [getMemecoinInfos, collectionAddress])

  const content = useMemo(() => {
    if (indexing) {
      return <Text.Body textAlign="center">Indexing...</Text.Body>
    }

    if (error) {
      return <Text.Body textAlign="center">This token is not unruggable</Text.Body>
    }

    if (!memecoinInfos) return

    return <Text.HeadlineLarge>{memecoinInfos.name}</Text.HeadlineLarge>
  }, [indexing, error, memecoinInfos])

  return (
    <Section>
      <Box className={styles.container}>{content}</Box>
    </Section>
  )
}
