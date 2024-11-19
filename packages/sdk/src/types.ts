import { AccountInterface, ProviderInterface, constants } from 'starknet'

export interface Config {
  starknetChainId: constants.StarknetChainId
  starknetProvider: ProviderInterface
}

export interface CreateMemecoinParameters {
  starknetAccount: AccountInterface
  name: string
  symbol: string
  owner: string
  initialSupply: string
}

export interface LaunchParameters {
  starknetAccount: AccountInterface
  memecoinAddress: string
  startingMarketCap: string
  holdLimit: string
  fees: string
  antiBotPeriodInSecs: number
  liquidityLockPeriod?: number
  currencyAddress: string
}

export interface CollectEkuboFeesParameters {
  starknetAccount: AccountInterface
  memecoinAddress: string
}
