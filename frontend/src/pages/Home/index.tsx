import clsx from 'clsx'
import { Link } from 'react-router-dom'
import onlyonstarknet from 'src/assets/onlyonstarknet.png'
import { PrimaryButton, SecondaryButton } from 'src/components/Button'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './style.css'

export default function HomePage() {
  return (
    <Box className={styles.container}>
      <Box as="span" className={clsx(styles.backgroundContainer, styles.background)} />

      <Column className={styles.titleContainer}>
        <Text.Custom as="h1" className={styles.title}>
          Unruggable Meme
        </Text.Custom>
        <Box as="img" src={onlyonstarknet} className={styles.subtitle} />
      </Column>

      <Column as="article" className={styles.firstArticle}>
        <p>
          Tired of getting rugpulled? Introducing Unruggable Meme, a memecoin standard and deployment tool designed to
          ensure a maximum safety for memecoin traders.
        </p>
        <Row gap="16" className={styles.buttonContainer}>
          <Link to="/launch">
            <PrimaryButton className={styles.firstArticleButton}>Launch</PrimaryButton>
          </Link>

          <Link to="/manage">
            <SecondaryButton className={styles.firstArticleButton}>Manage</SecondaryButton>
          </Link>
        </Row>
      </Column>
    </Box>
  )
}
