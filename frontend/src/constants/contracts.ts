import JediswapPair from 'src/abis/JediswapPair.json'
import Multicall from 'src/abis/Multicall.json'
import { constants, getChecksumAddress, json } from 'starknet'

interface TokenInfos {
  name: string
  symbol: string
}

type QuoteTokens = { [chainId in constants.StarknetChainId]: Record<string, TokenInfos> }

export const TOKEN_CLASS_HASH = '0x01c33d0d4f44faf5427c9131223e39e5bdbe9dd0f4f73dc527f05c50939d67f2'

export const FACTORY_ADDRESSES = {
  [constants.StarknetChainId.SN_GOERLI]: '0x061c3711a61c540fa60a6bd11ec09d36a4fc767c19253d6203c0ab3f251ed4b3',
  [constants.StarknetChainId.SN_MAIN]: '0xdead',
}

export const ETH_ADDRESS = '0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7'

export const MULTICALL_ADDRESS = '0x01a33330996310a1e3fa1df5b16c1e07f0491fdd20c441126e02613b948f0225'

export const JEDISWAP_ETH_USDC = {
  [constants.StarknetChainId.SN_GOERLI]: '0x05a2b2b37f66157f767ea711cb4e034c40d41f2f5acf9ff4a19049fa11c1a884',
  [constants.StarknetChainId.SN_MAIN]: '0x04d0390b777b424e43839cd1e744799f3de6c176c7e32c1812a41dbd9c19db6a',
}

const ETH_INFOS: TokenInfos = {
  name: 'Ether',
  symbol: 'ETH',
}

export const QUOTE_TOKENS: QuoteTokens = {
  [constants.StarknetChainId.SN_GOERLI]: {
    [getChecksumAddress(ETH_ADDRESS)]: ETH_INFOS,
  },
  [constants.StarknetChainId.SN_MAIN]: {
    [getChecksumAddress(ETH_ADDRESS)]: ETH_INFOS,
  },
}

export const compiledMulticall = json.parse(JSON.stringify(Multicall))
export const compiledJediswapPair = json.parse(JSON.stringify(JediswapPair))
