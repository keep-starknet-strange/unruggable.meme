import { constants, RpcProvider } from 'starknet'

import { Memecoin } from './memecoin'

export type FactoryConfig = {
  provider: RpcProvider
  chainId: constants.StarknetChainId
}

export abstract class FactoryInterface {
  public abstract config: FactoryConfig

  public abstract getMemecoin(address: string): Promise<Memecoin | undefined>
}
