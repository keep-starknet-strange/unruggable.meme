import { constants } from 'starknet'

import { Ether, LiquidityType } from '../src/constants'

export const notLaunched = {
  address: '0x3613d2f6e6d418bdc6022f55f0a94ff3e2bceaf8fa93345fb24a431226c4a53',

  baseMemecoin: {
    address: '0x3613d2f6e6d418bdc6022f55f0a94ff3e2bceaf8fa93345fb24a431226c4a53',
    decimals: 18,
    name: 'Unruggable',
    owner: '0x028446b7625A071Bd169022eE8C77c1aaD1E13D40994f54B2D84F8cDe6AA458D',
    symbol: 'Meme',
    totalSupply: '10000000000000000000000',
  },

  launchData: {
    isLaunched: false,
  },
}

export const launched = {
  address: '0x049201f03a0f0a9e70e28dcd74cbf44931174dbe3cc4b2ff488898339959e559',

  baseMemecoin: {
    address: '0x049201f03a0f0a9e70e28dcd74cbf44931174dbe3cc4b2ff488898339959e559',
    decimals: 18,
    name: 'Pain au lait',
    owner: '0x0000000000000000000000000000000000000000000000000000000000000000',
    symbol: 'PAL',
    totalSupply: '21000000000000000000000000',
  },

  launchData: {
    isLaunched: true,
    liquidity: {
      type: LiquidityType.EKUBO_NFT,
      ekuboId: '0x60ba3',
      lockManager: '0x3a03a6932ede59976814879e43153a47dacee9ab5a59f5c27297e5964c0fecc',
      owner: '0x0201dbb3E35Be8646c0670328f6A1b00a9F1804e5884C07f6410bB94EaB3baC8',
      poolKey: {
        token0: '0x049201F03A0F0A9E70E28Dcd74Cbf44931174DBe3CC4B2ff488898339959E559',
        token1: '0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7',
      },
      quoteToken: '0x049D36570D4e46f48e99674bd3fcc84644DdD6b96F7C741B1562B82f9e004dC7',
      unlockTime: 9999999999,
    },
    launch: {
      teamAllocation: '4000000000000000000000',
      blockNumber: 556061,
    },
    quoteToken: Ether[constants.StarknetChainId.SN_MAIN],
  },
}
