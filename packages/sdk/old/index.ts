import { CallData, hash, stark, uint256 } from 'starknet'

import { decimalsScale } from './utils'
import { DECIMALS, FACTORY_ADDRESSES, TOKEN_CLASS_HASH } from './constants'
import { Config, CreateMemecoinParameters } from './types'

export async function createMemecoin(config: Config, parameters: CreateMemecoinParameters) {
  const salt = stark.randomAddress()

  const constructorCalldata = CallData.compile([
    parameters.owner,
    parameters.name,
    parameters.symbol,
    uint256.bnToUint256(BigInt(parameters.initialSupply) * BigInt(decimalsScale(DECIMALS))),
    salt,
  ])

  const tokenAddress = hash.calculateContractAddressFromHash(
    salt,
    TOKEN_CLASS_HASH[config.starknetNetwork],
    constructorCalldata.slice(0, -1),
    FACTORY_ADDRESSES[config.starknetNetwork],
  )

  const calls = [
    {
      contractAddress: FACTORY_ADDRESSES[config.starknetNetwork],
      entrypoint: 'create_memecoin',
      calldata: constructorCalldata,
    },
  ]

  const response = await parameters.starknetAccount.execute(calls)

  return { tokenAddress, transactionHash: response.transaction_hash }
}
