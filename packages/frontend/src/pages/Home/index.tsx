import { useState } from 'react'
import clsx from 'clsx'
import { Link } from 'react-router-dom'
import onlyonstarknet from 'src/assets/onlyonstarknet.png'
import { PrimaryButton, SecondaryButton } from 'src/components/Button'
import { ImportTokenModal } from 'src/components/ImportTokenModal'
import { useImportTokenModal } from 'src/hooks/useModal'
import Box from 'src/theme/components/Box'
import { Column, Row } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './style.css'

// Feature data for the new landing page
const FEATURES = [
  {
    icon: '🔒',
    title: 'Locked Liquidity',
    description: 'All liquidity is locked on-chain forever. No rug pulls - your funds are safe.',
  },
  {
    icon: '🐋',
    title: 'Anti-Whale Protection',
    description: 'Maximum buy/sell limits prevent massive dumps that crash the price.',
  },
  {
    icon: '📊',
    title: 'Team Allocation Limits',
    description: 'Strict caps on team tokens ensure fair distribution to all holders.',
  },
  {
    icon: '🚀',
    title: 'Automated Deployment',
    description: 'Deploy your meme token in minutes with transparent, secure smart contracts.',
  },
]

const HOW_IT_WORKS = [
  {
    step: '1',
    title: 'Deploy Your Token',
    description: 'Choose your token name, symbol, and supply. Our contract handles the rest.',
  },
  {
    step: '2',
    title: 'Lock Liquidity',
    description: 'Automatically lock your liquidity pool to protect traders.',
  },
  {
    step: '3',
    title: 'Launch on DEX',
    description: 'List on JediSwap or Ekubo with confidence - no hidden traps.',
  },
]

export default function HomePage() {
  // modal
  const [, toggleImportTokenModel] = useImportTokenModal()
  
  // Dark mode toggle (for future implementation)
  const [isDarkMode] = useState(true)

  return (
    <>
      <Box className={styles.container}>
        <Box as="span" className={clsx(styles.backgroundContainer, styles.background)} />

        {/* Hero Section */}
        <Column className={styles.heroSection}>
          <Box className={styles.badge}>
            <Text.Custom as="span" className={styles.badgeText}>
              🔷 Built on Starknet
            </Text.Custom>
          </Box>
          
          <Text.Custom as="h1" className={styles.heroTitle}>
            Memecoins{' '}
            <Text.Custom as="span" className={styles.heroTitleHighlight}>
              Done Right
            </Text.Custom>
          </Text.Custom>
          
          <Text.Custom className={styles.heroSubtitle}>
            Launch fair, transparent memecoins on Starknet. No rug pulls, no hidden traps - just pure diamond hands energy.
          </Text.Custom>

          <Row gap="16" className={styles.heroButtons}>
            <Link to="/deploy">
              <PrimaryButton className={styles.ctaButton}>
                🚀 Deploy Now
              </PrimaryButton>
            </Link>
            <SecondaryButton className={styles.ctaButton} onClick={toggleImportTokenModel}>
              🔍 Check Token
            </SecondaryButton>
          </Row>

          <Row gap="32" className={styles.heroStats}>
            <Column alignItems="center" gap="4">
              <Text.Custom className={styles.statNumber}>$0</Text.Custom>
              <Text.Custom className={styles.statLabel}>Rugpulls</Text.Custom>
            </Column>
            <Box className={styles.statDivider} />
            <Column alignItems="center" gap="4">
              <Text.Custom className={styles.statNumber}>100%</Text.Custom>
              <Text.Custom className={styles.statLabel}>Audited</Text.Custom>
            </Column>
            <Box className={styles.statDivider} />
            <Column alignItems="center" gap="4">
              <Text.Custom className={styles.statNumber}>∞</Text.Custom>
              <Text.Custom className={styles.statLabel}>Liquidity Locked</Text.Custom>
            </Column>
          </Row>
        </Column>

        {/* Features Section */}
        <Column className={styles.section}>
          <Text.Custom as="h2" className={styles.sectionTitle}>
            Why Unruggable?
          </Text.Custom>
          <Text.Custom className={styles.sectionSubtitle}>
            Because your memes deserve better thanrug pulls
          </Text.Custom>
          
          <div className={styles.featuresGrid}>
            {FEATURES.map((feature, index) => (
              <Box key={index} className={styles.featureCard}>
                <Text.Custom as="span" className={styles.featureIcon}>{feature.icon}</Text.Custom>
                <Text.Custom as="h3" className={styles.featureTitle}>{feature.title}</Text.Custom>
                <Text.Custom className={styles.featureDescription}>{feature.description}</Text.Custom>
              </Box>
            ))}
          </div>
        </Column>

        {/* How It Works Section */}
        <Column className={styles.section}>
          <Text.Custom as="h2" className={styles.sectionTitle}>
            How It Works
          </Text.Custom>
          <Text.Custom className={styles.sectionSubtitle}>
            Launch your coin in 3 simple steps
          </Text.Custom>
          
          <div className={styles.stepsContainer}>
            {HOW_IT_WORKS.map((step, index) => (
              <Box key={index} className={styles.stepCard}>
                <Box className={styles.stepNumber}>{step.step}</Box>
                <Text.Custom as="h3" className={styles.stepTitle}>{step.title}</Text.Custom>
                <Text.Custom className={styles.stepDescription}>{step.description}</Text.Custom>
              </Box>
            ))}
          </div>
        </Column>

        {/* DEX Integration Section */}
        <Column className={styles.section}>
          <Text.Custom as="h2" className={styles.sectionTitle}>
            Supported Exchanges
          </Text.Custom>
          <div className={styles.dexContainer}>
            <Box className={styles.dexCard}>
              <Text.Custom className={styles.dexName}>JediSwap</Text.Custom>
              <Text.Custom className={styles.dexDescription}>Starknet's original AMM</Text.Custom>
            </Box>
            <Box className={styles.dexCard}>
              <Text.Custom className={styles.dexName}>Ekubo</Text.Custom>
              <Text.Custom className={styles.dexDescription}>Concentrated liquidity DEX</Text.Custom>
            </Box>
          </div>
        </Column>

        {/* Disclaimer Section */}
        <Box className={styles.disclaimer}>
          <Text.Custom as="h3" className={styles.disclaimerTitle}>
            ⚠️ Disclaimer
          </Text.Custom>
          <Text.Custom className={styles.disclaimerText}>
            Memecoins are highly volatile and risky. Only invest what you can afford to lose. 
            Always do your own research. This platform provides tools for fair token launches, 
            but we cannot guarantee the success or safety of any specific project.
          </Text.Custom>
        </Box>

        {/* Footer */}
        <Box className={styles.footer}>
          <Text.Custom className={styles.footerText}>
            Built with 💜 on Starknet
          </Text.Custom>
        </Box>
      </Box>

      <ImportTokenModal />
    </>
  )
}
