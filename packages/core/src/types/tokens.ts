import { constants } from 'starknet'

import { QUOTE_TOKEN_SYMBOL } from '../constants'

export type USDCPair = {
  address: string
  reversed: boolean
}

export type Token = {
  address: string
  symbol: QUOTE_TOKEN_SYMBOL
  name: string
  decimals: number
  camelCased?: boolean
  usdcPair?: USDCPair
}

export type MultichainToken = { [chainId in constants.StarknetChainId]: Token }

export type MultichainAddress = { [chainId in constants.StarknetChainId]: `0x${string}` }
