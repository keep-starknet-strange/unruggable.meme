import * as Icons from 'src/theme/components/Icons'
import { constants, getChecksumAddress } from 'starknet'

import { ETH_ADDRESS, JEDISWAP_ETH_USDC, JEDISWAP_STRK_USDC, STRK_ADDRESS, USDC_ADDRESSES } from './contracts'

interface USDCPair {
  address: string
  reversed: boolean
}

export interface Token {
  address: string
  symbol: string
  name: string
  decimals: number
  camelCased?: boolean
  icon: JSX.Element
  usdcPair?: USDCPair
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
    usdcPair: {
      address: JEDISWAP_ETH_USDC[constants.StarknetChainId.SN_GOERLI],
      reversed: true,
    },
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: ETH_ADDRESS,
    symbol: 'ETH',
    name: 'Ethereum',
    decimals: 18,
    camelCased: true,
    icon: <Icons.ETH />,
    usdcPair: {
      address: JEDISWAP_ETH_USDC[constants.StarknetChainId.SN_MAIN],
      reversed: false,
    },
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
    usdcPair: {
      address: JEDISWAP_STRK_USDC[constants.StarknetChainId.SN_GOERLI],
      reversed: true,
    },
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: STRK_ADDRESS,
    symbol: 'STRK',
    name: 'Stark',
    decimals: 18,
    camelCased: true,
    icon: <Icons.STRK />,
    usdcPair: {
      address: JEDISWAP_STRK_USDC[constants.StarknetChainId.SN_MAIN],
      reversed: false,
    },
  },
}

// USDC

const USDCoin: MultichainToken = {
  [constants.StarknetChainId.SN_GOERLI]: {
    address: USDC_ADDRESSES[constants.StarknetChainId.SN_GOERLI],
    symbol: 'USDC',
    name: 'USD Coin',
    decimals: 6,
    camelCased: true,
    icon: <Icons.USDC />,
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: USDC_ADDRESSES[constants.StarknetChainId.SN_MAIN],
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
    [getChecksumAddress(USDC_ADDRESSES[constants.StarknetChainId.SN_GOERLI])]:
      USDCoin[constants.StarknetChainId.SN_GOERLI],
  },
  [constants.StarknetChainId.SN_MAIN]: {
    [getChecksumAddress(ETH_ADDRESS)]: Ether[constants.StarknetChainId.SN_MAIN],
    [getChecksumAddress(STRK_ADDRESS)]: Stark[constants.StarknetChainId.SN_MAIN],
    [getChecksumAddress(USDC_ADDRESSES[constants.StarknetChainId.SN_MAIN])]: USDCoin[constants.StarknetChainId.SN_MAIN],
  },
}

export const DEFAULT_QUOTE_TOKEN_ADDRESS = ETH_ADDRESS
