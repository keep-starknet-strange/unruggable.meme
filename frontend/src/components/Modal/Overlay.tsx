import Box from 'src/theme/components/Box'

import * as styles from './Overlay.css'

interface OverlayProps {
  onClick: () => void
}

export default function Overlay({ onClick }: OverlayProps) {
  return <Box className={styles.overlay} onClick={onClick} />
}
