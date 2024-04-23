import { mainnet } from '@starknet-react/chains'
import { publicProvider, StarknetConfig } from '@starknet-react/core'
import { Factory } from 'core'
import { constants, RpcProvider } from 'starknet'

import { Provider } from '../src/providers/Provider'

const provider = new RpcProvider({
  nodeUrl: 'https://starknet-mainnet.public.blastapi.io',
})

const factory = new Factory({ provider, chainId: constants.StarknetChainId.SN_MAIN })

export const wrapper = ({ children }: { children: React.ReactNode }) => (
  <StarknetConfig provider={publicProvider()} chains={[mainnet]}>
    <Provider factory={factory}>{children}</Provider>
  </StarknetConfig>
)
