import { getChecksumAddress, shortString } from 'starknet'

import { DECIMALS, FACTORY_ADDRESSES, Selector } from '../constants'
import { multiCallContract } from '../utils/contract'
import { FactoryConfig, FactoryInterface } from './interface'
import { Memecoin } from './memecoin'

export class Factory implements FactoryInterface {
  public config: FactoryConfig

  constructor(config: FactoryConfig) {
    this.config = config
  }

  public async getMemecoin(address: string): Promise<Memecoin | undefined> {
    const result = await multiCallContract(this.config.provider, this.config.chainId, [
      {
        to: FACTORY_ADDRESSES[this.config.chainId],
        selector: Selector.IS_MEMECOIN,
        calldata: [address],
      },
      {
        to: address,
        selector: Selector.NAME,
      },
      {
        to: address,
        selector: Selector.SYMBOL,
      },
      {
        to: address,
        selector: Selector.OWNER,
      },
    ])

    const [[isMemecoin], [name], [symbol], [owner]] = result

    if (!+isMemecoin) return undefined

    return new Memecoin(this.config, {
      address,
      name: shortString.decodeShortString(name),
      symbol: shortString.decodeShortString(symbol),
      owner: getChecksumAddress(owner),
      decimals: DECIMALS,
    })
  }
}
