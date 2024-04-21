import { Fraction } from '@uniswap/sdk-core'
import { constants, RpcProvider } from 'starknet'

import { BaseMemecoin, Memecoin, MemecoinLaunchData } from '../types/memecoin'

export type FactoryConfig = {
  provider: RpcProvider
  chainId: constants.StarknetChainId
}

export abstract class FactoryInterface {
  public abstract config: FactoryConfig

  public abstract getMemecoin(address: string): Promise<Memecoin | undefined>
  public abstract getBaseMemecoin(address: string): Promise<BaseMemecoin | undefined>
  public abstract getMemecoinLaunchData(address: string): Promise<MemecoinLaunchData>

  public abstract getStartingMarketCap(memecoin: Memecoin, quoteTokenPriceAtLaunch?: Fraction): Fraction | undefined
}
