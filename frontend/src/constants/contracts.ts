import Multicall from 'src/contracts/Multicall.json'
import { constants, json } from 'starknet'

// Class hashes

// eslint-disable-next-line import/no-unused-modules
export const TOKEN_CLASS_HASH = '0x016261bfec15670ecc794d922fe87b6c1a250090d489811debf1b9c8cfac1225'

export const FACTORY_ADDRESSES = {
  [constants.StarknetChainId.SN_GOERLI]: '0x01745a0a5207bfbecdb024a17e2f6502dbb292fb0235ef7ea828091385fbc9b2',
  [constants.StarknetChainId.SN_MAIN]: '0xdead',
}

export const MULTICALL_ADDRESS = '0x01a33330996310a1e3fa1df5b16c1e07f0491fdd20c441126e02613b948f0225'

export const compiledMulticall = json.parse(JSON.stringify(Multicall.abi))
