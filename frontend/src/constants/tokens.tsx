import * as Icons from 'src/theme/components/Icons'
import { constants, getChecksumAddress } from 'starknet'

import { ETH_ADDRESS, STRK_ADDRESS, USDC_ADDRESS } from './contracts'

export interface Token {
  address: string
  symbol: string
  name: string
  decimals: number
  camelCased?: boolean
  icon: JSX.Element
}

type MultichainToken = { [chainId in constants.StarknetChainId]: Token }

// ETH

const Ether: MultichainToken = {
  [constants.StarknetChainId.SN_GOERLI]: {
    address: ETH_ADDRESS,
    symbol: 'ETH',
    name: 'Ethereum',
    decimals: 18,
    camelCased: true,
    icon: <Icons.ETH />,
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: ETH_ADDRESS,
    symbol: 'ETH',
    name: 'Ethereum',
    decimals: 18,
    camelCased: true,
    icon: <Icons.ETH />,
  },
}

// STRK

const Stark: MultichainToken = {
  [constants.StarknetChainId.SN_GOERLI]: {
    address: STRK_ADDRESS,
    symbol: 'STRK',
    name: 'Stark',
    decimals: 18,
    camelCased: true,
    icon: <Icons.STRK />,
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: STRK_ADDRESS,
    symbol: 'STRK',
    name: 'Stark',
    decimals: 18,
    camelCased: true,
    icon: <Icons.STRK />,
  },
}

// USDC

const USDCoin: MultichainToken = {
  [constants.StarknetChainId.SN_GOERLI]: {
    address: USDC_ADDRESS,
    symbol: 'USDC',
    name: 'USD Coin',
    decimals: 6,
    camelCased: true,
    icon: <Icons.USDC />,
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: USDC_ADDRESS,
    symbol: 'USDC',
    name: 'USD Coin',
    decimals: 6,
    camelCased: true,
    icon: <Icons.USDC />,
  },
}

// Quote tokens

type QuoteTokens = { [chainId in constants.StarknetChainId]: Record<string, Token> }

export const QUOTE_TOKENS: QuoteTokens = {
  [constants.StarknetChainId.SN_GOERLI]: {
    [getChecksumAddress(ETH_ADDRESS)]: Ether[constants.StarknetChainId.SN_GOERLI],
    [getChecksumAddress(STRK_ADDRESS)]: Stark[constants.StarknetChainId.SN_GOERLI],
    [getChecksumAddress(USDC_ADDRESS)]: USDCoin[constants.StarknetChainId.SN_GOERLI],
  },
  [constants.StarknetChainId.SN_MAIN]: {
    [getChecksumAddress(ETH_ADDRESS)]: Ether[constants.StarknetChainId.SN_MAIN],
    [getChecksumAddress(STRK_ADDRESS)]: Stark[constants.StarknetChainId.SN_MAIN],
    [getChecksumAddress(USDC_ADDRESS)]: USDCoin[constants.StarknetChainId.SN_MAIN],
  },
}

export const DEFAULT_QUOTE_TOKEN_ADDRESS = ETH_ADDRESS
