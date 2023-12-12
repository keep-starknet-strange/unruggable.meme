import { createPortal } from 'react-dom'

interface PortalProps {
  children: React.ReactNode
}

export default function Portal({ children }: PortalProps) {
  return createPortal(children, document.body)
}
