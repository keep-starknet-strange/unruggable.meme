import { constants } from 'starknet'

export type USDCPair = {
  address: string
  reversed: boolean
}

export type Token = {
  address: string
  symbol: string
  name: string
  decimals: number
  camelCased?: boolean
  usdcPair?: USDCPair
}

export type MultichainToken = { [chainId in constants.StarknetChainId]: Token }
