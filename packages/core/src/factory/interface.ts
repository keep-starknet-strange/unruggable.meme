import { Fraction } from '@uniswap/sdk-core'
import { CallDetails, constants, ProviderInterface } from 'starknet'

import {
  BaseMemecoin,
  EkuboLaunchData,
  LaunchedMemecoin,
  Memecoin,
  MemecoinDeployData,
  StandardAMMLaunchData,
} from '../types/memecoin'

export type FactoryConfig = {
  provider: ProviderInterface
  chainId: constants.StarknetChainId
}

export abstract class FactoryInterface {
  public abstract config: FactoryConfig

  public abstract getMemecoin(address: string): Promise<Memecoin | undefined>
  public abstract getBaseMemecoin(address: string): Promise<BaseMemecoin | undefined>
  public abstract getMemecoinLaunchData(address: string): Promise<LaunchedMemecoin>

  public abstract getStartingMarketCap(memecoin: Memecoin, quoteTokenPriceAtLaunch?: Fraction): Fraction | undefined

  public abstract getDeployCalldata(data: MemecoinDeployData): { tokenAddress: string; calls: CallDetails[] }
  public abstract getEkuboLaunchCalldata(memecoin: Memecoin, data: EkuboLaunchData): Promise<{ calls: CallDetails[] }>
  public abstract getStandardAMMLaunchCalldata(
    memecoin: Memecoin,
    data: StandardAMMLaunchData,
  ): Promise<{ calls: CallDetails[] }>
}
