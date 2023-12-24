import { createGlobalTheme, createGlobalThemeContract } from '@vanilla-extract/css'
import { createSprinkles, defineProperties } from '@vanilla-extract/sprinkles'
import { transparentize } from 'polished'

const themeContractValues = {
  colors: {
    text1: null,
    text2: null,

    bg1: null,
    bg2: null,

    appGradient: null,
    accentGradient: null,
    disabledGradient: null,

    border1: null,

    accent: null,
    error: null,
  },
  shadows: {
    none: null,
  },
  opacity: {
    hover: null,
    pressed: null,
  },
}

const themeVars = createGlobalThemeContract(themeContractValues, (_, path) => `unruggable-${path.join('-')}`)

const dimensions = {
  '0': '0',
  '2': '2',
  '4': '4px',
  '8': '8px',
  '12': '12px',
  '16': '16px',
  '18': '18px',
  '20': '20px',
  '24': '24px',
  '26': '26px',
  '28': '28px',
  '32': '32px',
  '42': '42px',
  '64': '64px',
  '180': '180px',
  '386': '386px',
  '480': '480px',
  half: '50%',
  full: '100%',
  min: 'min-content',
  max: 'max-content',
  viewHeight: '100vh',
  viewWidth: '100vw',
  auto: 'auto',
  inherit: 'inherit',
}

const spacing = {
  '0': '0',
  '1': '1px',
  '2': '2px',
  '4': '4px',
  '6': '6px',
  '8': '8px',
  '10': '10px',
  '12': '12px',
  '14': '14px',
  '16': '16px',
  '18': '18px',
  '20': '20px',
  '24': '24px',
  '28': '28px',
  '32': '32px',
  '42': '42px',
  '64': '64px',
  '88': '88px',
  '128': '128px',
  '256': '256px',
  '1/2': '50%',
  full: '100%',
  auto: 'auto',
  unset: 'unset',
}

const zIndices = {
  auto: 'auto',
  '1': '1',
  '2': '2',
  '3': '3',
  dropdown: '1000',
  sticky: '1020',
  modalBackdrop: '1040',
  modal: '1060',
  tooltip: '1080',
  modalOverTooltip: '1090',
}

export const vars = createGlobalTheme(':root', {
  color: {
    ...themeVars.colors,

    transparent: 'transparent',
    none: 'none',
    white: '#ffffff',
    black: '#000000',

    gray50: '#F5F6FC',
    gray100: '#E8ECFB',
    gray150: '#D2D9EE',
    gray200: '#B8C0DC',
    gray250: '#A6AFCA',
    gray300: '#98A1C0',
    gray350: '#888FAB',
    gray400: '#7780A0',
    gray450: '#6B7594',
    gray500: '#5D6785',
    gray550: '#505A78',
    gray600: '#404A67',
    gray650: '#333D59',
    gray700: '#293249',
    gray750: '#1B2236',
    gray800: '#131A2A',
    gray850: '#0E1524',
    gray900: '#0D111C',
    gray950: '#080B11',

    text1: '#f7f7f7',
    text2: '#5D6775',

    appGradient: `radial-gradient(50% 50% at 50% 30%, ${transparentize(0.9, '#6E44FF')}, transparent)`,
    accentGradient: 'linear-gradient(120deg, #ff003e, #6E44FF)',
    disabledGradient: 'linear-gradient(120deg, #86797c, #9d9aa7)',

    accent: '#6E44FF',

    error: '#ff003e',

    bg1: '#0c1012',
    bg2: '#1a1f23',

    border1: '#191B1D',
  },
  border: {
    light: '1px solid #191B1D',
    none: 'none',
  },
  radii: {
    '10': '10px',
    round: '9999px',
  },
  fontSize: {
    '0': '0',
    '10': '10px',
    '12': '12px',
    '14': '14px',
    '16': '16px',
    '18': '18px',
    '24': '24px',
    '28': '28px',
    '32': '32px',
    '36': '36px',
    '42': '42px',
    '48': '48px',
    '64': '64px',
    '72': '72px',
    '96': '96px',
  },
  lineHeight: {
    auto: 'auto',
    '1': '1px',
    '12': '12px',
    '14': '14px',
    '16': '16px',
    '20': '20px',
    '24': '24px',
    '28': '28px',
    '36': '36px',
    '44': '44px',
  },
  fontWeight: {
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
  },
  time: {
    '125': '125ms',
    '250': '250ms',
    '500': '500ms',
  },
})

const flexAlignment = [
  'flex-start',
  'center',
  'flex-end',
  'stretch',
  'baseline',
  'space-around',
  'space-between',
] as const

const overflow = ['hidden', 'inherit', 'scroll', 'visible', 'auto'] as const

const borderWidth = ['0px', '0.5px', '1px', '1.5px', '2px', '3px', '4px', '5px'] as const

const borderStyle = ['none', 'solid'] as const

const breakpoints = {
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  xxl: 1536,
  xxxl: 1920,
}

const opacity = {
  '0': '0',
  '0.1': '0.1',
  '0.3': '0.3',
  '0.5': '0.5',
  '0.7': '0.7',
  '1': '1',
  hover: '0.9',
  focus: '0.8',
}

// STYLES

const layoutStyles = defineProperties({
  conditions: {
    sm: {},
    md: { '@media': `screen and (min-width: ${breakpoints.sm}px)` },
    lg: { '@media': `screen and (min-width: ${breakpoints.md}px)` },
    xl: { '@media': `screen and (min-width: ${breakpoints.lg}px)` },
    xxl: { '@media': `screen and (min-width: ${breakpoints.xl}px)` },
    xxxl: { '@media': `screen and (min-width: ${breakpoints.xxl}px)` },
  },
  defaultCondition: 'sm',
  properties: {
    alignItems: flexAlignment,
    alignSelf: flexAlignment,
    justifyItems: flexAlignment,
    justifySelf: flexAlignment,
    placeItems: flexAlignment,
    placeContent: flexAlignment,
    fontSize: vars.fontSize,
    fontWeight: vars.fontWeight,
    lineHeight: vars.lineHeight,
    marginBottom: spacing,
    marginLeft: spacing,
    marginRight: spacing,
    marginTop: spacing,
    width: dimensions,
    height: dimensions,
    maxWidth: dimensions,
    minWidth: dimensions,
    maxHeight: dimensions,
    minHeight: dimensions,
    padding: spacing,
    paddingBottom: spacing,
    paddingLeft: spacing,
    paddingRight: spacing,
    paddingTop: spacing,
    bottom: spacing,
    left: spacing,
    right: spacing,
    top: spacing,
    margin: spacing,
    zIndex: zIndices,
    gap: spacing,
    flexShrink: spacing,
    flex: ['1', '1.5', '2', '3'],
    flexWrap: ['nowrap', 'wrap', 'wrap-reverse'],
    display: ['none', 'block', 'flex', 'inline-flex', 'inline-block', 'grid', 'inline'],
    whiteSpace: ['nowrap'],
    textOverflow: ['ellipsis'],
    textAlign: ['left', 'right', 'center', 'justify'],
    visibility: ['visible', 'hidden'],
    flexDirection: ['row', 'column', 'column-reverse'],
    justifyContent: flexAlignment,
    position: ['absolute', 'fixed', 'relative', 'sticky', 'static'],
    objectFit: ['contain', 'cover'],
    order: [0, 1],
  } as const,
  shorthands: {
    paddingX: ['paddingLeft', 'paddingRight'],
    paddingY: ['paddingTop', 'paddingBottom'],

    marginX: ['marginLeft', 'marginRight'],
    marginY: ['marginTop', 'marginBottom'],
  },
})

const colorStyles = defineProperties({
  conditions: {
    default: {},
    hover: { selector: '&:hover' },
    active: { selector: '&:active' },
    focus: { selector: '&:focus' },
    before: { selector: '&:before' },
    placeholder: { selector: '&::placeholder' },
  },
  defaultCondition: 'default',
  properties: {
    color: vars.color,
    background: vars.color,
    borderColor: vars.color,
    borderLeftColor: vars.color,
    borderBottomColor: vars.color,
    borderTopColor: vars.color,
    backgroundColor: vars.color,
    outlineColor: vars.color,
    fill: vars.color,
    opacity,
  } as const,
})

const unresponsiveProperties = defineProperties({
  conditions: {
    default: {},
    hover: { selector: '&:hover' },
    active: { selector: '&:active' },
    before: { selector: '&:before' },
    disabled: { selector: '&:disabled' },
  },
  defaultCondition: 'default',
  properties: {
    cursor: ['default', 'pointer', 'auto'],
    pointerEvents: ['none', 'all'],

    borderStyle,
    borderLeftStyle: borderStyle,
    borderBottomStyle: borderStyle,
    borderTopStyle: borderStyle,
    borderRadius: vars.radii,
    border: vars.border,
    borderBottom: vars.border,
    borderTop: vars.border,
    borderWidth,
    borderBottomWidth: borderWidth,
    borderTopWidth: borderWidth,

    outline: vars.border,
    outlineWidth: borderWidth,
    outlineStyle: borderStyle,

    textDecoration: ['none', 'underline'],

    overflow,
    overflowX: overflow,
    overflowY: overflow,

    transition: vars.time,
    transitionDuration: vars.time,
    animationDuration: vars.time,
    transitionTimingFunction: vars.time,
    animationTimingFunction: vars.time,
  },
})

export const sprinkles = createSprinkles(layoutStyles, colorStyles, unresponsiveProperties)
export type Sprinkles = Parameters<typeof sprinkles>[0]
