import OriginalNavBarItem from '@theme-original/NavbarItem'
import { TraceEvent } from '@uniswap/analytics'

import { BrowserEvent, SharedEventName } from '../utils/analyticsEvents'

// eslint-disable-next-line import/no-unused-modules
export default function NavbarItem(props: { className: string; label: string }) {
  return (
    <>
      <TraceEvent events={[BrowserEvent.onClick]} element={props.label} name={SharedEventName.NAVBAR_CLICKED}>
        <OriginalNavBarItem {...props} />
      </TraceEvent>
    </>
  )
}
