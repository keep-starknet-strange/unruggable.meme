import { Factory, constants as coreConstants } from 'core'
import { getChecksumAddress } from 'starknet'
import moment from 'moment'

import { CollectEkuboFeesParameters, Config, CreateMemecoinParameters, LaunchParameters } from './types'
import { convertPercentageStringToPercent, normalizeAmountString, validateStarknetAddress } from './utils'
import { STARKNET_MAX_BLOCK_TIME } from './constants'

/**
 * Initializes a new Factory instance with the provided configuration.
 *
 * @param {Config} config - The configuration object containing the Starknet provider and chain ID.
 * @returns {Factory} A new Factory instance.
 */
function getFactory(config: Config): Factory {
  return new Factory({ provider: config.starknetProvider, chainId: config.starknetChainId })
}

/**
 * Retrieves a meme coin instance from the factory by its address.
 *
 * @param {Factory} factory - The factory instance to use for retrieval.
 * @param {string} memecoinAddress - The address of the meme coin to retrieve.
 * @returns {Promise<any>} A promise that resolves to the meme coin instance if found, or throws an error if not found.
 */
async function getMemecoin(factory: Factory, memecoinAddress: string) {
  if (!validateStarknetAddress(memecoinAddress)) {
    throw new Error('Invalid Starknet address')
  }
  const memecoin = await factory.getMemecoin(memecoinAddress)
  if (!memecoin) {
    throw new Error(`Memecoin with address ${memecoinAddress} not found`)
  }
  return memecoin
}

/**
 * Creates a new meme coin on the Starknet network.
 *
 * @param {Config} config - The configuration object containing the Starknet provider.
 * @param {CreateMemecoinParameters} parameters - The parameters for creating the meme coin.
 * @returns {Promise<{transactionHash: string, tokenAddress: string}>} A promise that resolves to an object containing the transaction hash and the token address.
 */
export async function createMemecoin(config: Config, parameters: CreateMemecoinParameters) {
  const factory = getFactory(config)
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
  } catch (error) {
    console.error('Error creating meme coin:', error)
    throw new Error(`Failed to create meme coin: ${error.message}`)
  }
}

/**
 * Initiates the launch of a meme coin on an Ekubo pool.
 *
 * @param {Config} config - The configuration object containing the Starknet provider.
 * @param {LaunchParameters} parameters - The parameters for launching the meme coin on Ekubo.
 * @returns {Promise<{transactionHash: string}>} A promise that resolves to an object containing the transaction hash.
 */
export async function launchOnEkubo(config: Config, parameters: LaunchParameters) {
  const factory = getFactory(config)
  const memecoin = await getMemecoin(factory, parameters.memecoinAddress)
  const quoteToken = coreConstants.QUOTE_TOKENS[config.starknetChainId][getChecksumAddress(parameters.currencyAddress)]

  const { calls } = await factory.getEkuboLaunchCalldata(memecoin, {
    amm: coreConstants.AMM.EKUBO,
    antiBotPeriod: parameters.antiBotPeriodInSecs * 60,
    fees: convertPercentageStringToPercent(parameters.fees),
    holdLimit: convertPercentageStringToPercent(parameters.holdLimit),
    quoteToken,
    startingMarketCap: normalizeAmountString(parameters.startingMarketCap),
    teamAllocations: parameters.teamAllocations,
  })

  try {
    const response = await parameters.starknetAccount.execute(calls)
    return { transactionHash: response.transaction_hash }
  } catch (error) {
    console.error('Error launching on Ekubo:', error)
    throw new Error(`Failed to launch on Ekubo: ${error.message}`)
  }
}

export async function launchOnStandardAMM(config: Config, parameters: LaunchParameters) {
  const factory = getFactory(config)
  const memecoin = await getMemecoin(factory, parameters.memecoinAddress)
  const quoteToken = coreConstants.QUOTE_TOKENS[config.starknetChainId][getChecksumAddress(parameters.currencyAddress)]

  const { calls } = await factory.getStandardAMMLaunchCalldata(memecoin, {
    amm: coreConstants.AMM.JEDISWAP,
    antiBotPeriod: parameters.antiBotPeriodInSecs * 60,
    holdLimit: convertPercentageStringToPercent(parameters.holdLimit),
    quoteToken,
    startingMarketCap: normalizeAmountString(parameters.startingMarketCap),
    teamAllocations: parameters.teamAllocations,
    liquidityLockPeriod:
      parameters.liquidityLockPeriod === coreConstants.MAX_LIQUIDITY_LOCK_PERIOD // liquidity lock until
        ? coreConstants.LIQUIDITY_LOCK_FOREVER_TIMESTAMP
        : moment().add(moment.duration(parameters.liquidityLockPeriod, 'months')).unix() + STARKNET_MAX_BLOCK_TIME,
  })

  try {
    const response = await parameters.starknetAccount.execute(calls)
    return { transactionHash: response.transaction_hash }
  } catch (error) {
    console.error('Error launching on Standard AMM:', error)
    throw new Error(`Failed to launch on Standard AMM: ${error.message}`)
  }
}

/**
 * Collects Ekubo fees
 *
 * @param {Config} config - The configuration object containing the StarkNet provider and chain ID.
 * @param {CollectEkuboFeesParameters} parameters - The parameters for collecting Ekubo fees, including the Starknet account and memecoin address.
 * @returns {Promise<{transactionHash: string}>} A promise that resolves to an object containing the transaction hash if successful, or null if failed.
 */
export async function collectEkuboFees(config: Config, parameters: CollectEkuboFeesParameters) {
  const factory = getFactory(config)
  const memecoin = await getMemecoin(factory, parameters.memecoinAddress)

  const result = await factory.getCollectEkuboFeesCalldata(memecoin)
  if (result) {
    try {
      const response = await parameters.starknetAccount.execute(result.calls)
      return { transactionHash: response.transaction_hash }
    } catch (error) {
      console.error('Error collecting Ekubo fees:', error)
      throw new Error(`Failed to collect Ekubo fees: ${error.message}`)
    }
  }
  return null
}
