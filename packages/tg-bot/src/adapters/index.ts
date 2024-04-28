import { ArgentAdapter } from './ArgentAdapter'
import { WebAdapter } from './WebAdapter'

export const Adapters = {
  argentMobile: {
    adapter: ArgentAdapter,
    name: 'Argent Mobile',
  },
  webBrowser: {
    adapter: WebAdapter,
    name: 'Desktop Web Browser',
  },
}
