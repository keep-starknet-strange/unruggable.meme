import { Fraction } from '@uniswap/sdk-core'

import {
  getBaseMemecoin,
  getDeployCalldata,
  getEkuboFees,
  getEkuboLaunchCalldata,
  getMemecoinLaunchData,
  getStandardAMMLaunchCalldata,
  getStartingMarketCap,
} from '../actions'
import {
  BaseMemecoin,
  EkuboLaunchData,
  LaunchedMemecoin,
  Memecoin,
  MemecoinDeployData,
  StandardAMMLaunchData,
} from '../types/memecoin'
import { FactoryConfig, FactoryInterface } from './interface'

export class Factory implements FactoryInterface {
  public config: FactoryConfig

  constructor(config: FactoryConfig) {
    this.config = config
  }

  public async getMemecoin(address: string): Promise<Memecoin | undefined> {
    const [baseMemecoin, launchData] = await Promise.all([
      this.getBaseMemecoin(address),
      this.getMemecoinLaunchData(address),
    ])

    if (!baseMemecoin) return undefined

    return { ...baseMemecoin, ...launchData }
  }

  public async getBaseMemecoin(address: string): Promise<BaseMemecoin | undefined> {
    return getBaseMemecoin(this.config, address)
  }

  public async getMemecoinLaunchData(address: string): Promise<LaunchedMemecoin> {
    return getMemecoinLaunchData(this.config, address)
  }

  public getStartingMarketCap(memecoin: Memecoin, quoteTokenPriceAtLaunch?: Fraction): Fraction | undefined {
    return getStartingMarketCap(memecoin, quoteTokenPriceAtLaunch)
  }

  public async getEkuboFees(memecoin: Memecoin): Promise<Fraction | undefined> {
    return getEkuboFees(this.config, memecoin)
  }

  public getDeployCalldata(data: MemecoinDeployData) {
    return getDeployCalldata(this.config, data)
  }

  public async getEkuboLaunchCalldata(memecoin: Memecoin, data: EkuboLaunchData) {
    return getEkuboLaunchCalldata(this.config, memecoin, data)
  }

  public async getStandardAMMLaunchCalldata(memecoin: Memecoin, data: StandardAMMLaunchData) {
    return getStandardAMMLaunchCalldata(this.config, memecoin, data)
  }
}
