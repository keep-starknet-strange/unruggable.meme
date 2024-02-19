import { constants, getChecksumAddress } from 'starknet'

import { ETH_ADDRESS } from './contracts'

export interface Token {
  address: string
  symbol: string
  decimals: number
  camelCased?: boolean
}

type MultichainToken = { [chainId in constants.StarknetChainId]: Token }

// ETH

const Ether: MultichainToken = {
  [constants.StarknetChainId.SN_GOERLI]: {
    address: ETH_ADDRESS,
    symbol: 'ETH',
    decimals: 18,
    camelCased: true,
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: ETH_ADDRESS,
    symbol: 'ETH',
    decimals: 18,
    camelCased: true,
  },
}

// Quote tokens

type QuoteTokens = { [chainId in constants.StarknetChainId]: Record<string, Token> }

export const QUOTE_TOKENS: QuoteTokens = {
  [constants.StarknetChainId.SN_GOERLI]: {
    [getChecksumAddress(ETH_ADDRESS)]: Ether[constants.StarknetChainId.SN_GOERLI],
  },
  [constants.StarknetChainId.SN_MAIN]: {
    [getChecksumAddress(ETH_ADDRESS)]: Ether[constants.StarknetChainId.SN_MAIN],
  },
}

export const DEFAULT_QUOTE_TOKEN_ADDRESS = ETH_ADDRESS
