/* eslint-disable @typescript-eslint/no-var-requires */
import './theme/css/global.css'

import React from 'react'
import { createRoot } from 'react-dom/client'

import App from './App'
import { HooksSDKProvider, StarknetProvider } from './components/Web3Provider'

window.Buffer = window.Buffer || require('buffer').Buffer

const container = document.getElementById('root')
if (!container) throw 'Undefined #root container'

const root = createRoot(container)
root.render(
  <StarknetProvider>
    <HooksSDKProvider>
      <App />
    </HooksSDKProvider>
  </StarknetProvider>,
)
