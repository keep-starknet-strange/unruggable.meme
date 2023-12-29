import Section from 'src/components/Section'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'
import * as Text from 'src/theme/components/Text'

import * as styles from './style.css'

/**
 * AboutPage component
 */
export default function AboutPage() {
  return (
    <Section>
      <Box className={styles.container}>
        <Column gap="10">
          <Text.HeadlineMedium>About</Text.HeadlineMedium>
          <Text.Body>
            Tired of rug pulls and scammy meme coins stealing your gains? Unruggable.meme presents a revolutionary way
            to deploy meme magic with unimpeachable security. Our buzzword-compliant smart contracts let you moon freely
            without worrying about shady developers making off with the liquidity pool in the middle of the night.
          </Text.Body>
          <Text.Body>
            We achieve this through rigorous self-verification and immutable contract logic. All our contracts inherit
            from trustworthy base classes that cannot be upgraded or altered after deployment. This guarantees certain
            key properties like:
          </Text.Body>
          <ul>
            <li>Maximum percentage of team allocation not more than 10%.</li>
            <li>Maximum percentage of supply than can be bought at once at 2%.</li>
            <li>
              Pre-Launch safeguards: This prevents too many addresses from holding the token before launch. Maximum
              holders before launch is set to 10.
            </li>
            <li>No hidden backdoors.</li>
          </ul>
          <Text.Body>
            In short, we turn &ldquo;wen rug&rdquo; into &ldquo;never rug&rdquo; with the power of Cairo and highly
            opinionated code.
          </Text.Body>
          <Text.Body>
            But before you ape in more $STARK than you can afford to lose, be aware unruggable doesn&apos;t mean
            unrisky. At the end of the day these are still speculative meme tokens at the mercy of the crypto
            market&apos;s manic whims. Only bet what you&apos;re willing to lose on this readme compliant rollercoaster!
          </Text.Body>
          <Text.Body>
            For the daring degens among you, check out our currently deployed contracts and{' '}
            <a href="https://github.com/keep-starknet-strange/unruggable.meme" target="_blank" rel="noreferrer">
              repo
            </a>
            . And never hesitate to review the code and verify things for yourself on{' '}
            <a href="https://voyager.online/" target="_blank" rel="noreferrer">
              Voyager
            </a>{' '}
            or{' '}
            <a href="https://starkscan.co/" target="_blank" rel="noreferrer">
              StarkScan
            </a>
            . We pride ourselves on 100% transparency - feel free to audit to your heart&apos;s content!
          </Text.Body>
          <Text.Body>Now let&apos;s bring some trustworthy meme magic into this irrational market!</Text.Body>
        </Column>
      </Box>
    </Section>
  )
}
