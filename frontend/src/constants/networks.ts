import { Chain, goerli, mainnet } from '@starknet-react/chains'
import { ChainProviderFactory } from '@starknet-react/core'
import { RpcProvider } from 'starknet'

const NETHERMIND_KEY = process.env.REACT_APP_NETHERMIND_KEY

export const nethermindRpcProviders: ChainProviderFactory | null = NETHERMIND_KEY
  ? (chain: Chain) => {
      switch (chain.id) {
        case goerli.id:
          return new RpcProvider({
            nodeUrl: `https://rpc.nethermind.io/goerli-juno/?apikey=${NETHERMIND_KEY}`,
          })

        case mainnet.id:
          return new RpcProvider({
            nodeUrl: `https://rpc.nethermind.io/mainnet-juno/?apikey=${NETHERMIND_KEY}`,
          })

        default:
          return null
      }
    }
  : null
