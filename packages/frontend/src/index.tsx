/* eslint-disable @typescript-eslint/no-var-requires */
import './theme/css/global.css'

import React from 'react'
import { createRoot } from 'react-dom/client'

import App from './App'
import { StarknetProvider } from './components/Web3Provider'
import MemecoinUpdater from './state/memecoin/updater'

function Updaters() {
  return (
    <>
      <MemecoinUpdater />
    </>
  )
}

window.Buffer = window.Buffer || require('buffer').Buffer

const container = document.getElementById('root')
if (!container) throw 'Undefined #root container'

const root = createRoot(container)
root.render(
  <StarknetProvider>
    <Updaters />
    <App />
  </StarknetProvider>,
)
