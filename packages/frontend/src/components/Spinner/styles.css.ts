import { keyframes, style } from '@vanilla-extract/css'
import { vars } from 'src/theme/css/sprinkles.css'

const rotateAnimation = keyframes({
  '100%': {
    transform: 'rotate(360deg)',
  },
})

const dashAnimation = keyframes({
  '0%': {
    strokeDasharray: '1, 150',
    strokeDashoffset: '0',
    // stroke-dasharray: 1, 150;
    // stroke-dashoffset: 0;
  },
  '50%': {
    strokeDasharray: '90, 150',
    strokeDashoffset: '-35',
  },
  '100%': {
    strokeDasharray: '90, 150',
    strokeDashoffset: '-124',
  },
})

export const spinner = style([
  {
    animation: rotateAnimation,
    animationDuration: '2s',
    animationIterationCount: 'infinite',
    animationTimingFunction: 'linear',
    width: '50px',
    height: '50px',
  },
])

export const dashSpinner = style([
  {
    animation: dashAnimation,
    animationDuration: '1.5s',
    animationIterationCount: 'infinite',
    animationTimingFunction: 'linear',
    stroke: vars.color.text1,
    strokeLinecap: 'round',
  },
])
