import { Factory, constants as coreConstants } from 'core'
import { constants, getChecksumAddress } from 'starknet'
import { Config, CreateMemecoinParameters, LaunchOnEkuboParameters } from './types'
import { isValidL2Address, parseFormatedAmount, parseFormatedPercentage } from './utils'

/**
 * Creates a new meme coin on the Starknet network.
 *
 * @param {Config} config - The configuration object containing the Starknet provider.
 * @param {CreateMemecoinParameters} parameters - The parameters for creating the meme coin.
 * @returns {Promise<{transactionHash: string, tokenAddress: string}>} A promise that resolves to an object containing the transaction hash and the token address.
 */
export async function createMemecoin(config: Config, parameters: CreateMemecoinParameters) {
  const factory = new Factory({ provider: config.starknetProvider, chainId: constants.StarknetChainId.SN_MAIN })
  try {
    const data = {
      initialSupply: parameters.initialSupply,
      name: parameters.name,
      owner: parameters.owner,
      symbol: parameters.symbol,
    }
    const { calls, tokenAddress } = factory.getDeployCalldata(data)
    const response = await parameters.starknetAccount.execute(calls)
    return { transactionHash: response.transaction_hash, tokenAddress }
  } catch (e: any) {
    console.error('Error creating meme coin:', e)
  }
  return null
}

/**
 * Initiates the launch of a meme coin on an Ekubo pool.
 *
 * @param {Config} config - The configuration object containing the Starknet provider.
 * @param {LaunchOnEkuboParameters} parameters - The parameters for launching the meme coin on Ekubo.
 * @returns {Promise<{transactionHash: string}>} A promise that resolves to an object containing the transaction hash.
 */
export async function launchOnEkubo(config: Config, parameters: LaunchOnEkuboParameters) {
  const factory = new Factory({ provider: config.starknetProvider, chainId: constants.StarknetChainId.SN_MAIN })

  if (!isValidL2Address(parameters.memecoinAddress)) {
    throw new Error('Invalid Starknet address')
  }

  const memecoin = await factory.getMemecoin(parameters.memecoinAddress)
  if (!memecoin) {
    throw new Error('Memecoin not found')
  }

  const { calls } = await factory.getEkuboLaunchCalldata(memecoin, {
    amm: coreConstants.AMM.EKUBO,
    antiBotPeriod: parameters.antiBotPeriodInSecs * 60,
    fees: parseFormatedPercentage(parameters.fees),
    holdLimit: parseFormatedPercentage(parameters.holdLimit),
    quoteToken: {
      address: '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7',
      decimals: 18,
      name: 'ETH',
      symbol: coreConstants.QUOTE_TOKEN_SYMBOL.ETH,
    },
    startingMarketCap: parseFormatedAmount(parameters.startingMarketCap),
    teamAllocations: [],
  })

  try {
    const response = await parameters.starknetAccount.execute(calls)
    return { transactionHash: response.transaction_hash }
  } catch (e) {
    console.error('Error', e)
    return null
  }
}
