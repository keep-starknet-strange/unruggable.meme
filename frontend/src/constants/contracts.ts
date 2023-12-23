import { constants } from 'starknet'

// Class hashes

// eslint-disable-next-line import/no-unused-modules
export const TOKEN_CLASS_HASH = '0x015a2494ca74d9a049f3917cc2a3b6cacc5d294fd67c0c8414c16f56cba1bb45'

export const FACTORY_ADDRESSES = {
  [constants.StarknetChainId.SN_GOERLI]: '0x04f1a3345b89847febb961c61376a1bc3cb72bbbc680e156369b3cda858419ee',
  [constants.StarknetChainId.SN_MAIN]: '0xdead',
}

export const LOCKER_ADDRESSES = {
  [constants.StarknetChainId.SN_GOERLI]: '0x01d28399e4aca5d93e709d7405ad81b6ebb3c4b82e7f75b72372fdb83ee33953',
  [constants.StarknetChainId.SN_MAIN]: '0xdead',
}
