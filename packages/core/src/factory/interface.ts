import { Fraction } from '@uniswap/sdk-core'
import { CallDetails, constants, ProviderInterface } from 'starknet'

import {
  BaseMemecoin,
  DeployData,
  EkuboLaunchData,
  LaunchedMemecoin,
  Memecoin,
  StandardAMMLaunchData,
} from '../types/memecoin'

export type FactoryConfig = {
  provider: ProviderInterface
  chainId: constants.StarknetChainId
}

// TODO: Add comments
export abstract class FactoryInterface {
  public abstract config: FactoryConfig

  public abstract getMemecoin(address: string): Promise<Memecoin | undefined>

  public abstract getBaseMemecoin(address: string): Promise<BaseMemecoin | undefined>

  public abstract getMemecoinLaunchData(address: string): Promise<LaunchedMemecoin>

  public abstract getStartingMarketCap(memecoin: Memecoin, quoteTokenPriceAtLaunch?: Fraction): Fraction | undefined

  public abstract getEkuboFees(memecoin: Memecoin): Promise<Fraction | undefined>

  public abstract getCollectEkuboFeesCalldata(memecoin: Memecoin): { calls: CallDetails[] } | undefined

  public abstract getExtendLiquidityLockCalldata(
    memecoin: Memecoin,
    seconds: number,
  ): { calls: CallDetails[] } | undefined

  public abstract getDeployCalldata(data: DeployData): { tokenAddress: string; calls: CallDetails[] }

  public abstract getEkuboLaunchCalldata(memecoin: Memecoin, data: EkuboLaunchData): Promise<{ calls: CallDetails[] }>

  public abstract getStandardAMMLaunchCalldata(
    memecoin: Memecoin,
    data: StandardAMMLaunchData,
  ): Promise<{ calls: CallDetails[] }>
}
