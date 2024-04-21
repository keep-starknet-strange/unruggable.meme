import { constants } from 'starknet'

export interface USDCPair {
  address: string
  reversed: boolean
}

export interface Token {
  address: string
  symbol: string
  name: string
  decimals: number
  camelCased?: boolean
  usdcPair?: USDCPair
}

export type MultichainToken = { [chainId in constants.StarknetChainId]: Token }
