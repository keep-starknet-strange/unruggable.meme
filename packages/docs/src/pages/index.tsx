import './styles.module.css'

import Link from '@docusaurus/Link'
import useBaseUrl from '@docusaurus/useBaseUrl'
import Telegram from '@site/static/img/telegram.svg'
import GitHub from '@site/static/img/github.svg'
import Npm from '@site/static/img/npm.svg'
import Layout from '@theme/Layout'
import ThemedImage from '@theme/ThemedImage'
import { TraceEvent } from '@uniswap/analytics'
import React from 'react'
import { ArrowUpRight as LinkIcon, BookOpen, HelpCircle, Info, Settings } from 'react-feather'
import styled from 'styled-components'

import {
  BrowserEvent,
  DocsHomepageElementName as ElementName,
  DocsSectionName as SectionName,
  SharedEventName,
} from '../utils/analyticsEvents'

const actions = [
  {
    title: 'What is Unruggable memecoin',
    icon: Info,
    to: '/tutorial/overview',
    text: `Learn how to deploy and launch your first Unruggable memecoin`,
  },
  {
    title: 'How does Unruggable works',
    icon: Settings,
    to: '/concepts/overview',
    text: `Learn about the core concepts of the Unruggable Protocol, Liquidity lock, Anti bot, Single side Liquidity and more.`,
  },
  {
    title: 'Integrate with Unruggable',
    icon: HelpCircle,
    to: '/sdk/overview',
    text: `Learn how to integrate Unruggable into you dApp through guided examples.`,
  },
  {
    title: 'The Unruggable smart contracts',
    icon: BookOpen,
    to: '/contracts/overview',
    text: `Learn about the architecture of the Unruggable Protocol smart contracts through guided examples.`,
  },
]

const Container = styled.div`
  display: flex;
  flex-direction: column;
  width: 100%;
  margin: 0 auto 4rem auto;
`

const StyledTitle = styled.h1`
  font-size: 64px !important;
  text-shadow: 2px 4px 0 var(--ifm-color-black);
  color: white;
  font-size: 64px;
  font-weight: 800;
`

const Row = styled.div`
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-gap: 16px;
  justify-content: center;
  margin: 0 auto;
  padding: 1rem 0;
  max-width: 960px;

  @media (max-width: 960px) {
    grid-template-columns: 1fr;
    padding: 1rem;
    max-width: 100%;
    margin: 0 1rem;
  }
  @media (max-width: 640px) {
    grid-template-columns: 1fr;
  }
`

const Card = styled.div`
  display: flex;
  max-height: 250px;
  min-width: 350px;
  padding: 1rem;
  flex-direction: column;
  justify-content: center;
  cursor: pointer;
  border: 1px solid transparent;
  border-radius: 20px;
  border: 1px solid var(--ifm-color-emphasis-200);
  /* flex: 1 1 0px; */

  &:hover {
    border: 1px solid var(--ifm-color-emphasis-400);
    box-shadow: 0px 6px 10px rgba(0, 0, 0, 0.05);
  }

  @media (max-width: 960px) {
    width: 100%;
  }
`

const CenterCard = styled(Card)`
  min-width: 250px;
  justify-content: space-between;
  align-items: center;
  flex-direction: row;

  display: grid;
  grid-template-columns: 48px 1fr;
  gap: 24px;

  h3 {
    margin-bottom: 0.25rem;
  }

  p {
    margin-bottom: 0px;
  }
`

const ShadowCard = styled(Card)`
  box-shadow: 0px 6px 10px rgba(0, 0, 0, 0.05);
  background-color: #ffffff10;
  backdrop-filter: blur(10px);
  min-height: 200px;
  /* background-color: var(--ifm-color-emphasis-0); */
`

const IconWrapper = styled.div`
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  margin-right: 0.5rem;
`

const LinkIconWrapper = styled.div`
  opacity: 0.25;
`

const TopSection = styled.div`
  width: 100%;
  align-items: center;
  justify-content: space-between;
  display: flex;
  flex-direction: row;
  margin-bottom: 1rem;
`

const DocsHeader = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  overflow: hidden;
  width: 100%;
  position: relative;
`

const StyledImage = styled(ThemedImage)`
  position: relative;
  z-index: -1;
  width: 100%;
  object-fit: cover;
`

const StyledTitleImage = styled(StyledImage)`
  width: 100%;
  height: 100%;
  object-fit: cover;
  z-index: -1;
  position: absolute;
  opacity: 0.2;
  mask-image: linear-gradient(rgba(0, 0, 0, 1), transparent);
`

const StyledIcon = styled.div`
  svg {
    fill: var(--ifm-font-color-base);
  }
`

// eslint-disable-next-line import/no-unused-modules
export default function Home() {
  return (
    <Layout title={`Unruggable Docs`} description="Technical Documentation For The Unruggable Protocol">
      <Container>
        <DocsHeader>
          <div
            style={{
              padding: '4rem 0  ',
              textAlign: 'center',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
            }}
          >
            <StyledTitle>Unruggable Docs</StyledTitle>
          </div>
          <StyledTitleImage
            sources={{
              light: useBaseUrl('/img/background-light.png'),
              dark: useBaseUrl('/img/background-dark.png'),
            }}
          />
          <Row>
            {actions.map((action) => (
              <TraceEvent
                key={action.to}
                element={action.to}
                events={[BrowserEvent.onClick]}
                name={SharedEventName.PAGE_CLICKED}
                section={SectionName.WELCOME_LINKS}
              >
                <Link style={{ textDecoration: 'none' }} to={action.to}>
                  <ShadowCard key={action.title}>
                    <TopSection>
                      <IconWrapper>
                        <action.icon style={{ width: '24px' }} />
                      </IconWrapper>
                      <LinkIconWrapper>
                        <LinkIcon />
                      </LinkIconWrapper>
                    </TopSection>
                    <h3 style={{ marginBottom: '.75rem', fontWeight: 500 }}>{action.title}</h3>
                    <p style={{ marginBottom: '0.5rem', fontWeight: 300 }}>{action.text}</p>
                  </ShadowCard>
                </Link>
              </TraceEvent>
            ))}
          </Row>

          <hr />

          <Row>
            <TraceEvent
              events={[BrowserEvent.onClick]}
              element={ElementName.TELEGRAM}
              section={SectionName.BOTTOM_MENU_LINKS}
              name={SharedEventName.PAGE_CLICKED}
            >
              <Link style={{ textDecoration: 'none' }} href={'https://t.me/UnruggableMeme'}>
                <CenterCard>
                  <Telegram style={{ width: '48px', height: '48px' }} />
                  <div>
                    <h3>Telegram</h3>
                    <p>Join our Telegram Community.</p>
                  </div>
                </CenterCard>
              </Link>
            </TraceEvent>

            <TraceEvent
              events={[BrowserEvent.onClick]}
              section={SectionName.BOTTOM_MENU_LINKS}
              element={ElementName.GITHUB}
              name={SharedEventName.PAGE_CLICKED}
            >
              <Link
                style={{ textDecoration: 'none' }}
                href={'https://github.com/keep-starknet-strange/unruggable.meme'}
              >
                <CenterCard>
                  <StyledIcon>
                    <GitHub style={{ width: '48px', height: '48px' }} />
                  </StyledIcon>

                  <div>
                    <h3>GitHub</h3>
                    <p>View all Unruggable code.</p>
                  </div>
                </CenterCard>
              </Link>
            </TraceEvent>
          </Row>
        </DocsHeader>
      </Container>
    </Layout>
  )
}
