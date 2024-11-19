import { AccountInterface, ProviderInterface } from 'starknet'

export interface Config {
/*   starknetNetwork: Network */
  starknetProvider: ProviderInterface
}

export interface CreateMemecoinParameters {
  starknetAccount: AccountInterface
  name: string
  symbol: string
  owner: string
  initialSupply: string
}
