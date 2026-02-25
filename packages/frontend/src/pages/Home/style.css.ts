import { style } from '@vanilla-extract/css'
import { transparentize } from 'polished'
import { sprinkles, vars } from 'src/theme/css/sprinkles.css'

export const container = style([
  sprinkles({
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    textAlign: 'center',
    overflow: 'auto',
    paddingBottom: {
      sm: '88',
      md: '32',
    },
  }),
])

export const backgroundContainer = style([
  {
    zIndex: '-99',
    position: 'absolute',
    top: '0',
    right: '0',
    bottom: '0',
    left: '0',
    height: '100vh',
    maxHeight: '1000px',
  },
])

export const background = style([
  {
    backgroundImage: `
      linear-gradient(to bottom, ${transparentize(0.3, '#000000')}, ${vars.color.bg1}),
      url("src/assets/background.png")
    `,
    backgroundSize: 'cover',
    backgroundPosition: 'center',
    backgroundRepeat: 'no-repeat',
  },
  sprinkles({
    position: 'absolute',
    top: '0',
    right: '0',
    bottom: '0',
    left: '0',
    width: 'full',
    height: 'full',
  }),
])

// New Hero Section Styles
export const heroSection = style([
  sprinkles({
    paddingX: '32',
    paddingY: '64',
    textAlign: 'center',
    gap: '24',
  }),
  {
    maxWidth: '900px',
    margin: '0 auto',
  },
])

export const badge = style([
  {
    display: 'inline-block',
    background: 'linear-gradient(135deg, rgba(90, 24, 155, 0.3), rgba(139, 92, 246, 0.2))',
    border: '1px solid rgba(139, 92, 246, 0.4)',
    borderRadius: '9999px',
    padding: '8px 20px',
  },
])

export const badgeText = style([
  {
    color: '#a78bfa',
    fontSize: '14px',
    fontWeight: '600',
  },
])

export const heroTitle = style([
  {
    fontSize: 'clamp(36px, 8vw, 72px)',
    fontWeight: '900',
    lineHeight: '1.1',
    letterSpacing: '-0.02em',
    color: '#ffffff',
  },
])

export const heroTitleHighlight = style([
  {
    background: 'linear-gradient(135deg, #c084fc, #8b5cf6, #6366f1)',
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent',
    backgroundClip: 'text',
  },
])

export const heroSubtitle = style([
  {
    fontSize: 'clamp(16px, 3vw, 20px)',
    color: '#94a3b8',
    maxWidth: '600px',
    margin: '0 auto',
    lineHeight: '1.6',
  },
])

export const heroButtons = style([
  sprinkles({
    justifyContent: 'center',
    marginTop: '8',
  }),
])

export const ctaButton = style([
  {
    padding: '14px 32px',
    fontSize: '16px',
    fontWeight: '700',
    borderRadius: '12px',
    transition: 'all 0.2s ease',
    ':hover': {
      transform: 'translateY(-2px)',
      boxShadow: '0 10px 40px rgba(139, 92, 246, 0.3)',
    },
  },
])

export const heroStats = style([
  sprinkles({
    justifyContent: 'center',
    marginTop: '32',
    paddingX: '24',
    paddingY: '16',
  }),
  {
    background: 'rgba(255, 255, 255, 0.03)',
    borderRadius: '16px',
    border: '1px solid rgba(255, 255, 255, 0.08)',
  },
])

export const statNumber = style([
  {
    fontSize: '28px',
    fontWeight: '800',
    color: '#c084fc',
  },
])

export const statLabel = style([
  {
    fontSize: '12px',
    color: '#64748b',
    textTransform: 'uppercase',
    letterSpacing: '0.1em',
  },
])

export const statDivider = style([
  {
    width: '1px',
    height: '40px',
    background: 'rgba(255, 255, 255, 0.1)',
  },
])

// Section Styles
export const section = style([
  sprinkles({
    paddingX: '32',
    paddingY: '64',
    width: 'full',
  }),
  {
    maxWidth: '1200px',
    margin: '0 auto',
  },
])

export const sectionTitle = style([
  {
    fontSize: 'clamp(28px, 5vw, 42px)',
    fontWeight: '800',
    color: '#ffffff',
    marginBottom: '8px',
  },
])

export const sectionSubtitle = style([
  {
    fontSize: '18px',
    color: '#64748b',
    marginBottom: '48px',
  },
])

// Features Grid
export const featuresGrid = style([
  {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
    gap: '24px',
  },
])

export const featureCard = style([
  {
    padding: '28px',
    background: 'rgba(255, 255, 255, 0.03)',
    borderRadius: '16px',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    transition: 'all 0.3s ease',
    ':hover': {
      background: 'rgba(255, 255, 255, 0.06)',
      border: '1px solid rgba(139, 92, 246, 0.3)',
      transform: 'translateY(-4px)',
    },
  },
])

export const featureIcon = style([
  {
    fontSize: '36px',
    display: 'block',
    marginBottom: '16px',
  },
])

export const featureTitle = style([
  {
    fontSize: '20px',
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: '8px',
  },
])

export const featureDescription = style([
  {
    fontSize: '14px',
    color: '#94a3b8',
    lineHeight: '1.6',
  },
])

// Steps
export const stepsContainer = style([
  {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
    gap: '32px',
  },
])

export const stepCard = style([
  {
    padding: '32px',
    background: 'rgba(255, 255, 255, 0.03)',
    borderRadius: '16px',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    textAlign: 'center',
  },
])

export const stepNumber = style([
  {
    width: '48px',
    height: '48px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background: 'linear-gradient(135deg, #8b5cf6, #6366f1)',
    borderRadius: '12px',
    fontSize: '24px',
    fontWeight: '800',
    color: '#ffffff',
    margin: '0 auto 20px',
  },
])

export const stepTitle = style([
  {
    fontSize: '20px',
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: '12px',
  },
])

export const stepDescription = style([
  {
    fontSize: '14px',
    color: '#94a3b8',
    lineHeight: '1.6',
  },
])

// DEX Section
export const dexContainer = style([
  {
    display: 'flex',
    justifyContent: 'center',
    gap: '24px',
    flexWrap: 'wrap',
  },
])

export const dexCard = style([
  {
    padding: '24px 48px',
    background: 'rgba(255, 255, 255, 0.03)',
    borderRadius: '16px',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    textAlign: 'center',
    minWidth: '200px',
    transition: 'all 0.2s ease',
    ':hover': {
      background: 'rgba(255, 255, 255, 0.06)',
      border: '1px solid rgba(139, 92, 246, 0.3)',
    },
  },
])

export const dexName = style([
  {
    fontSize: '20px',
    fontWeight: '700',
    color: '#ffffff',
    marginBottom: '4px',
  },
])

export const dexDescription = style([
  {
    fontSize: '14px',
    color: '#64748b',
  },
])

// Disclaimer
export const disclaimer = style([
  sprinkles({
    paddingX: '32',
    paddingY: '24',
  }),
  {
    maxWidth: '800px',
    margin: '0 auto',
    background: 'rgba(239, 68, 68, 0.1)',
    borderRadius: '12px',
    border: '1px solid rgba(239, 68, 68, 0.2)',
  },
])

export const disclaimerTitle = style([
  {
    fontSize: '16px',
    fontWeight: '700',
    color: '#fca5a5',
    marginBottom: '8px',
  },
])

export const disclaimerText = style([
  {
    fontSize: '14px',
    color: '#fca5a5',
    lineHeight: '1.6',
    opacity: '0.9',
  },
])

// Footer
export const footer = style([
  sprinkles({
    paddingX: '32',
    paddingY: '32',
  }),
  {
    borderTop: '1px solid rgba(255, 255, 255, 0.05)',
    marginTop: '32px',
  },
])

export const footerText = style([
  {
    fontSize: '14px',
    color: '#64748b',
  },
])

// Legacy styles (kept for compatibility)
export const titleContainer = sprinkles({
  textAlign: 'center',
  gap: '16',
  paddingX: '32',
})

export const title = style([
  sprinkles({
    fontSize: '48',
    fontWeight: 'extraBold',
    color: 'white',
  }),
])

export const subtitle = style([
  sprinkles({
    fontSize: '16',
    color: 'grey2',
  }),
])

export const firstArticle = style([
  sprinkles({
    marginTop: '32',
    width: 'full',
    maxWidth: '600',
  }),
])

export const firstArticleText = style([
  sprinkles({
    fontSize: '16',
    color: 'grey2',
  }),
])

export const buttonContainer = sprinkles({
  marginTop: '24',
  justifyContent: 'center',
})

export const firstArticleButton = style([
  {
    minWidth: '160px',
  },
])
