import { CallData, hash, stark, uint256 } from 'starknet'

import { DECIMALS, FACTORY_ADDRESSES, Selector, TOKEN_CLASS_HASH } from '../constants'
import { FactoryConfig } from '../factory'
import { MemecoinDeployData } from '../types'
import { decimalsScale } from '../utils/helpers'

export function getDeployCalldata(config: FactoryConfig, data: MemecoinDeployData) {
  const salt = stark.randomAddress()

  const constructorCalldata = CallData.compile([
    data.owner,
    data.name,
    data.symbol,
    uint256.bnToUint256(BigInt(data.initialSupply) * BigInt(decimalsScale(DECIMALS))),
    salt,
  ])

  const tokenAddress = hash.calculateContractAddressFromHash(
    salt,
    TOKEN_CLASS_HASH[config.chainId],
    constructorCalldata.slice(0, -1),
    FACTORY_ADDRESSES[config.chainId],
  )

  const calls = [
    {
      contractAddress: FACTORY_ADDRESSES[config.chainId],
      entrypoint: Selector.CREATE_MEMECOIN,
      calldata: constructorCalldata,
    },
  ]

  return { tokenAddress, calls }
}
