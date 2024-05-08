import { BASE_URL, SEPOLIA_BASE_URL } from '@avnu/avnu-sdk'
import { starknetChainId } from '@starknet-react/core'
import { constants } from 'starknet'

export function getAvnuOptions(chainId: bigint | undefined): { baseUrl: string } {
  const actualChainId = chainId ?? BigInt(constants.StarknetChainId.SN_MAIN)

  return {
    baseUrl: starknetChainId(actualChainId) === constants.StarknetChainId.SN_MAIN ? BASE_URL : SEPOLIA_BASE_URL,
  }
}
