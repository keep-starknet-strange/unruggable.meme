import React, { useCallback, useMemo } from 'react'
import Box from 'src/theme/components/Box'
import { Row } from 'src/theme/components/Flex'
import { vars } from 'src/theme/css/sprinkles.css'

import * as styles from './style.css'

// const Unit = styled(Text.Body)`
//   background: ${({ theme }) => theme.bg3}80;
//   padding: 0 6px;
//   border-radius: 6px;
//   height: 32px;
//   display: flex;
//   align-items: center;
//   text-align: center;
//   justify-content: center;
// `

interface SliderProps {
  value: number
  unit?: string
  unitWidth?: number
  min?: number
  step?: number
  max: number
  loading?: boolean
  onSlidingChange: (value: number) => void
  addon?: React.PropsWithChildren['children']
}

export default function Slider({ value, min = 0, step = 1, max, addon, onSlidingChange }: SliderProps) {
  const sliderStyle = useMemo(
    () => ({
      background: `linear-gradient(to right, transparent 0%, transparent ${((value - min) / (max - min)) * 100}%, ${
        vars.color.bg2
      } ${((value - min) / (max - min)) * 100}%, ${vars.color.bg2} 100%)`,
    }),
    [value, min, max],
  )

  const handleSlidingUpdate = useCallback(
    (event: React.FormEvent<HTMLInputElement>) => {
      const newValue = (event.target as HTMLInputElement).value

      if (newValue === '' || /^([0-9]+)$/.test(newValue))
        onSlidingChange(newValue.length > 0 ? Math.min(+newValue, max) : 0)
    },
    [max, onSlidingChange],
  )

  return (
    <Row gap="16" zIndex="1">
      <Box
        as="input"
        type="range"
        min={min}
        max={max}
        value={value}
        step={step}
        onChange={handleSlidingUpdate}
        style={sliderStyle}
        className={styles.slider}
      />

      {addon}
    </Row>
  )
}
