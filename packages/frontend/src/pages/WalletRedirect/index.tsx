import QRCode from 'qrcode'
import { useEffect, useRef } from 'react'
import { useParams } from 'react-router-dom'
import { PrimaryButton } from 'src/components/Button'
import Section from 'src/components/Section'
import Box from 'src/theme/components/Box'
import { Column } from 'src/theme/components/Flex'

import * as styles from './style.css'

export default function WalletRedirect() {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const { redirectUrl } = useParams()
  const decodedUrl = decodeURIComponent(redirectUrl ?? '')

  useEffect(() => {
    if (!canvasRef.current) return

    QRCode.toCanvas(canvasRef.current, decodedUrl, {
      width: 512,
    })

    // Redirect to the URL
    window.location.href = decodedUrl
  }, [decodedUrl])

  const onButtonClick = () => {
    window.location.href = decodedUrl
  }

  return (
    <Section>
      <Box className={styles.container}>
        <Column gap="14">
          <canvas ref={canvasRef} className={styles.canvas} />

          <PrimaryButton type="submit" large onClick={onButtonClick}>
            Open Wallet
          </PrimaryButton>
        </Column>
      </Box>
    </Section>
  )
}
