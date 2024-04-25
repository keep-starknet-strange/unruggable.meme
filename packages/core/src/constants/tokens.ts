import { constants, getChecksumAddress } from 'starknet'

import { MultichainToken, Token } from '../types/tokens'
import { ETH_ADDRESSES, JEDISWAP_ETH_USDC, JEDISWAP_STRK_USDC, STRK_ADDRESSES, USDC_ADDRESSES } from './contracts'

export enum QUOTE_TOKEN_SYMBOL {
  ETH = 'ETH',
  STRK = 'STRK',
  USDC = 'USDC',
}

// ETH
export const Ether: MultichainToken = {
  [constants.StarknetChainId.SN_GOERLI]: {
    address: ETH_ADDRESSES[constants.StarknetChainId.SN_GOERLI],
    symbol: QUOTE_TOKEN_SYMBOL.ETH,
    name: 'Ether',
    decimals: 18,
    camelCased: true,
    usdcPair: {
      address: JEDISWAP_ETH_USDC[constants.StarknetChainId.SN_GOERLI],
      reversed: true,
    },
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: ETH_ADDRESSES[constants.StarknetChainId.SN_MAIN],
    symbol: QUOTE_TOKEN_SYMBOL.ETH,
    name: 'Ether',
    decimals: 18,
    camelCased: true,
    usdcPair: {
      address: JEDISWAP_ETH_USDC[constants.StarknetChainId.SN_MAIN],
      reversed: false,
    },
  },
}

// STRK
export const Stark: MultichainToken = {
  [constants.StarknetChainId.SN_GOERLI]: {
    address: STRK_ADDRESSES[constants.StarknetChainId.SN_GOERLI],
    symbol: QUOTE_TOKEN_SYMBOL.STRK,
    name: 'Stark',
    decimals: 18,
    camelCased: true,
    usdcPair: {
      address: JEDISWAP_STRK_USDC[constants.StarknetChainId.SN_GOERLI],
      reversed: true,
    },
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: STRK_ADDRESSES[constants.StarknetChainId.SN_MAIN],
    symbol: QUOTE_TOKEN_SYMBOL.STRK,
    name: 'Stark',
    decimals: 18,
    camelCased: true,
    usdcPair: {
      address: JEDISWAP_STRK_USDC[constants.StarknetChainId.SN_MAIN],
      reversed: false,
    },
  },
}

// USDC
export const USDCoin: MultichainToken = {
  [constants.StarknetChainId.SN_GOERLI]: {
    address: USDC_ADDRESSES[constants.StarknetChainId.SN_GOERLI],
    symbol: QUOTE_TOKEN_SYMBOL.USDC,
    name: 'USD Coin',
    decimals: 6,
    camelCased: true,
  },
  [constants.StarknetChainId.SN_MAIN]: {
    address: USDC_ADDRESSES[constants.StarknetChainId.SN_MAIN],
    symbol: QUOTE_TOKEN_SYMBOL.USDC,
    name: 'USD Coin',
    decimals: 6,
    camelCased: true,
  },
}

// Quote tokens

export const QUOTE_TOKENS: { [chainId in constants.StarknetChainId]: Record<string, Token> } = {
  [constants.StarknetChainId.SN_GOERLI]: {
    [getChecksumAddress(ETH_ADDRESSES[constants.StarknetChainId.SN_GOERLI])]:
      Ether[constants.StarknetChainId.SN_GOERLI],

    [getChecksumAddress(STRK_ADDRESSES[constants.StarknetChainId.SN_GOERLI])]:
      Stark[constants.StarknetChainId.SN_GOERLI],

    [getChecksumAddress(USDC_ADDRESSES[constants.StarknetChainId.SN_GOERLI])]:
      USDCoin[constants.StarknetChainId.SN_GOERLI],
  },

  [constants.StarknetChainId.SN_MAIN]: {
    [getChecksumAddress(ETH_ADDRESSES[constants.StarknetChainId.SN_MAIN])]: Ether[constants.StarknetChainId.SN_MAIN],
    [getChecksumAddress(STRK_ADDRESSES[constants.StarknetChainId.SN_MAIN])]: Stark[constants.StarknetChainId.SN_MAIN],
    [getChecksumAddress(USDC_ADDRESSES[constants.StarknetChainId.SN_MAIN])]: USDCoin[constants.StarknetChainId.SN_MAIN],
  },
}

export const DEFAULT_QUOTE_TOKEN_ADDRESSES = {
  [constants.StarknetChainId.SN_GOERLI]: getChecksumAddress(ETH_ADDRESSES[constants.StarknetChainId.SN_GOERLI]),
  [constants.StarknetChainId.SN_MAIN]: getChecksumAddress(ETH_ADDRESSES[constants.StarknetChainId.SN_MAIN]),
}
