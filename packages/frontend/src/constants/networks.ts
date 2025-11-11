import { Chain, goerli, mainnet } from '@starknet-react/chains'
import { ChainProviderFactory } from '@starknet-react/core'
import { RpcProvider } from 'starknet'

export const SUPPORTED_STARKNET_NETWORKS = [mainnet, goerli]

const DEFAULT_NETWORK_NAME = process.env.REACT_APP_DEFAULT_NETWORK_NAME as string
if (typeof DEFAULT_NETWORK_NAME === 'undefined') {
  throw new Error(`REACT_APP_DEFAULT_NETWORK_NAME must be a defined environment variable`)
} else if (SUPPORTED_STARKNET_NETWORKS.every(({ network }) => network !== DEFAULT_NETWORK_NAME)) {
  throw new Error(`REACT_APP_DEFAULT_NETWORK_NAME is invalid`)
}

export const blastRpcProviders: ChainProviderFactory = (chain: Chain) => {
  switch (chain.id) {
    case goerli.id:
      return new RpcProvider({
        nodeUrl: `https://starknet-sepolia.public.blastapi.io`,
      })

    case mainnet.id:
      return new RpcProvider({
        nodeUrl: `https://starknet.drpc.org`,
      })

    default:
      return null
  }
}
