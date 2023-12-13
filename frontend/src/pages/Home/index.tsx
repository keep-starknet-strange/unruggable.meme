import { Link } from 'react-router-dom'
import onlyonstarknet from 'src/assets/onlyonstarknet.png'
import { PrimaryButton, SecondaryButton } from 'src/components/Button'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'
import clsx from 'clsx'

import * as styles from './style.css'

export default function HomePage() {
  return (
    <Box>
      <Box as="span" className={clsx(styles.backgroundContainer, styles.background)} />
      <Column className={styles.titleContainer}>
        <Text.HeadlineLarge className={styles.title}>Unruggable Memecoin</Text.HeadlineLarge>
        <Box as="img" src={onlyonstarknet} className={styles.subtitle} />
      </Column>

      <Column as="article" className={styles.firstArticle}>
        <Text.HeadlineMedium>The pioneer framework to build safer memecoins</Text.HeadlineMedium>
        <Row gap="16">
          <Link to="/launch">
            <PrimaryButton className={styles.firstArticleButton}>Launch</PrimaryButton>
          </Link>

          <Link to="/manage">
            <SecondaryButton className={styles.firstArticleButton}>Manage</SecondaryButton>
          </Link>
        </Row>
      </Column>

      <Column as="article" className={styles.secondArticle}>
        <Box>
          <Text.Custom color="text2" marginLeft="8" fontWeight="normal" fontSize="18">
            Meet Unruggable Meme
          </Text.Custom>

          <Text.Body>
            Tired of getting rugpulled? Introducing Unruggable Memecoin, a project designed with security and
            transparency at its core. Your go-to platform for deploying safer memecoins on starknet.
            <br />
            <br />
            Our innovative contracts and safeguards ensure a fair and secure experience for all users.
          </Text.Body>
        </Box>
      </Column>
    </Box>
  )
}
