import { createPortal } from 'react-dom'

export default function Portal({ children }: React.PropsWithChildren) {
  return createPortal(children, document.body)
}
