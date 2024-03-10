import EkuboPositions from 'src/abis/EkuboPositions.json'
import JediswapPair from 'src/abis/JediswapPair.json'
import Multicall from 'src/abis/Multicall.json'
import { constants, json } from 'starknet'

export const TOKEN_CLASS_HASH = {
  [constants.StarknetChainId.SN_GOERLI]: '0x05ba9aea47a8dd7073ab82b9e91721bdb3a2c1b259cffd68669da1454faa80ac',
  [constants.StarknetChainId.SN_MAIN]: '0x05ba9aea47a8dd7073ab82b9e91721bdb3a2c1b259cffd68669da1454faa80ac',
}

export const FACTORY_ADDRESSES = {
  [constants.StarknetChainId.SN_GOERLI]: '0x076c3112e95994507c44c72b8dfb7f8d568a370d2f7c2d918ed9f55327671385',
  [constants.StarknetChainId.SN_MAIN]: '0x06468f3cc11291b601e13f863c482850bbefa7eee20c6682573cff0be9de4152',
}

export const EKUBO_POSITIONS_ADDRESSES = {
  [constants.StarknetChainId.SN_GOERLI]: '0x073fa8432bf59f8ed535f29acfd89a7020758bda7be509e00dfed8a9fde12ddc',
  [constants.StarknetChainId.SN_MAIN]: '0x02e0af29598b407c8716b17f6d2795eca1b471413fa03fb145a5e33722184067',
}

export const ETH_ADDRESS = '0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7'

export const MULTICALL_ADDRESS = '0x01a33330996310a1e3fa1df5b16c1e07f0491fdd20c441126e02613b948f0225'

export const JEDISWAP_ETH_USDC = {
  [constants.StarknetChainId.SN_GOERLI]: '0x05a2b2b37f66157f767ea711cb4e034c40d41f2f5acf9ff4a19049fa11c1a884',
  [constants.StarknetChainId.SN_MAIN]: '0x04d0390b777b424e43839cd1e744799f3de6c176c7e32c1812a41dbd9c19db6a',
}

export const compiledMulticall = json.parse(JSON.stringify(Multicall))
export const compiledJediswapPair = json.parse(JSON.stringify(JediswapPair))
export const compiledEkuboPositions = json.parse(JSON.stringify(EkuboPositions))
