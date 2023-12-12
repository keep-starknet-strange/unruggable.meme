import { style } from '@vanilla-extract/css'
import { sprinkles } from 'src/theme/css/sprinkles.css'
import { vars } from 'src/theme/css/vars.css'

export const Nav = style([
  {
    boxShadow: `0px 8px 16px 0 ${vars.color.bg1Transparent}`,
  },
  sprinkles({
    position: 'sticky',
    top: '0',
    padding: '24',
    background: 'bg1',
    zIndex: 'sticky',
  }),
])

export const logoContainer = sprinkles({
  color: 'text1',
  width: '42',
  height: '42',
  cursor: 'pointer',
})

export const baseSideContainer = sprinkles({
  display: 'flex',
  flex: '1',
  flexShrink: '2',
  width: 'full',
})

export const leftSideContainer = style([
  baseSideContainer,
  sprinkles({
    flex: '1',
    justifyContent: 'flex-start',
  }),
])

export const rightSideContainer = style([
  baseSideContainer,
  sprinkles({
    flex: '1',
    justifyContent: 'flex-end',
  }),
])
