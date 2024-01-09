import Multicall from 'src/contracts/Multicall.json'
import { constants, json } from 'starknet'

// Class hashes

// eslint-disable-next-line import/no-unused-modules
export const TOKEN_CLASS_HASH = '0x015a2494ca74d9a049f3917cc2a3b6cacc5d294fd67c0c8414c16f56cba1bb45'

export const FACTORY_ADDRESSES = {
  [constants.StarknetChainId.SN_GOERLI]: '0x07cc35da454fe2dc8bd36ef826a86d04cd51c42568a912fe8dcc9e0f581c5a0f',
  [constants.StarknetChainId.SN_MAIN]: '0xdead',
}

export const LOCKER_ADDRESSES = {
  [constants.StarknetChainId.SN_GOERLI]: '0x01d28399e4aca5d93e709d7405ad81b6ebb3c4b82e7f75b72372fdb83ee33953',
  [constants.StarknetChainId.SN_MAIN]: '0xdead',
}

export const MULTICALL_ADDRESS = '0x01a33330996310a1e3fa1df5b16c1e07f0491fdd20c441126e02613b948f0225'

export const compiledMulticall = json.parse(JSON.stringify(Multicall.abi))
