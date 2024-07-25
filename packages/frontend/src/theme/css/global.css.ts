import { globalStyle } from '@vanilla-extract/css'

import { vars } from './sprinkles.css'

globalStyle('*', {
  fontFamily: "'Inter', sans-serif",
  boxSizing: 'border-box',
})

globalStyle('html, body', {
  margin: 0,
  padding: 0,
  overflow: 'hidden',
})

globalStyle('html', {
  fontSize: 16,
  fontVariant: 'none',
  color: 'black',
  WebkitFontSmoothing: 'antialiased',
  MozOsxFontSmoothing: 'grayscale',
  WebkitTapHighlightColor: 'rgba(0, 0, 0, 0)',
  height: '100%',
})

globalStyle('html, body, #root', {
  height: '100%',
})

globalStyle('#root', {
  position: 'relative',
  width: '100%',
  minHeight: '100%',
  overflow: 'auto',
})

globalStyle('html', {
  backgroundColor: vars.color.bg1,
})

globalStyle('a', {
  textDecoration: 'none',
  color: vars.color.accent,
})

globalStyle('a:hover', {
  textDecoration: 'none',
})

globalStyle('button', {
  userSelect: 'none',
})
