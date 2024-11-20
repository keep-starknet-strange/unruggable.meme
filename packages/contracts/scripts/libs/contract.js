import 'dotenv/config'
import * as fs from 'fs'
import * as path from 'path'
import colors from 'colors'
import { fileURLToPath } from 'url'
import { json } from 'starknet'
import { getNetwork, getAccount } from './network.js'
import { getExchanges } from './exchange.js'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const TARGET_PATH = path.join(__dirname, '..', '..', 'target', 'dev')

const getContracts = () => {
  if (!fs.existsSync(TARGET_PATH)) {
    throw new Error(`Target directory not found at path: ${TARGET_PATH}`)
  }
  const contracts = fs.readdirSync(TARGET_PATH).filter((contract) => contract.includes('.contract_class.json'))
  if (contracts.length === 0) {
    throw new Error('No build files found. Run `scarb build` first')
  }
  return contracts
}

const getLockManagerPath = () => {
  const contracts = getContracts()

  const tokenLocker = contracts.find((contract) => contract.includes('LockManager'))
  if (!tokenLocker) {
    throw new Error('TokenLocker contract not found. Run `scarb build` first')
  }
  return path.join(TARGET_PATH, tokenLocker)
}

const getEkuboLauncherPath = () => {
  const contracts = getContracts()
  const ekuboLauncher = contracts.find((contract) => contract.includes('EkuboLauncher'))
  if (!ekuboLauncher) {
    throw new Error('EkuboLauncher contract not found. Run `scarb build` first')
  }
  return path.join(TARGET_PATH, ekuboLauncher)
}

const getUnruggableMemecoinPath = () => {
  const contracts = getContracts()
  const unruggableMemecoin = contracts.find((contract) => contract.includes('UnruggableMemecoin'))
  if (!unruggableMemecoin) {
    throw new Error('UnruggableMemecoin contract not found. Run `scarb build` first')
  }
  return path.join(TARGET_PATH, unruggableMemecoin)
}

const getFactoryPath = () => {
  const contracts = getContracts()
  const factory = contracts.find((contract) => contract.includes('Factory'))
  if (!factory) {
    throw new Error('Factory contract not found. Run `scarb build` first')
  }
  return path.join(TARGET_PATH, factory)
}

const declare = async (filepath, contract_name) => {
  console.log(`\nDeclaring ${contract_name}...`.magenta)
  const compiledSierraCasm = filepath.replace('.contract_class.json', '.compiled_contract_class.json')
  const compiledFile = json.parse(fs.readFileSync(filepath).toString('ascii'))
  const compiledSierraCasmFile = json.parse(fs.readFileSync(compiledSierraCasm).toString('ascii'))
  const account = getAccount()

  const contract = await account.declareIfNot({
    contract: compiledFile,
    casm: compiledSierraCasmFile,
  })

  const network = getNetwork(process.env.STARKNET_NETWORK)
  console.log(`- Class Hash: `.magenta, `${contract.class_hash}`)
  if (contract.transaction_hash) {
    console.log('- Tx Hash: '.magenta, `${network.explorer_url}/tx/${contract.transaction_hash})`)
    await account.waitForTransaction(contract.transaction_hash)
  } else {
    console.log('- Tx Hash: '.magenta, 'Already declared')
  }

  return contract
}

export const deployLockManager = async (minLockTime, lockPositionClassHash) => {
  // Load account
  const account = getAccount()

  // Declare contract

  const path = getLockManagerPath()
  console.log('=> path', path)
  const locker = await declare(path, 'LockManager')

  // Deploy contract
  console.log(`\nDeploying LockManager...`.green)
  console.log('Min lock time: '.green, minLockTime)
  const contract = await account.deployContract({
    classHash: locker.class_hash,
    constructorCalldata: [minLockTime, lockPositionClassHash],
  })

  // Wait for transaction
  const network = getNetwork(process.env.STARKNET_NETWORK)
  console.log('Tx hash: '.green, `${network.explorer_url}/tx/${contract.transaction_hash})`)
  await account.waitForTransaction(contract.transaction_hash)
}

export const deployEkuboLauncher = async () => {
  // Load account
  const account = getAccount()

  const ekuboLauncher = await declare(getEkuboLauncherPath(), 'EkuboLauncher')
  console.log('=> ekuboLauncher', ekuboLauncher)

  const contract = await account.deployContract({
    classHash: ekuboLauncher.class_hash,
    constructorCalldata: [
      '0x0444a09d96389aa7148f1aada508e30b71299ffe650d9c97fdaae38cb9a23384', // ekubo core
      '0x04484f91f0d2482bad844471ca8dc8e846d3a0211792322e72f21f0f44be63e5', // ekubo registry
      '0x06a2aee84bb0ed5dded4384ddd0e40e9c1372b818668375ab8e3ec08807417e5', // ekubo positions
      '0x0045f933adf0607292468ad1c1dedaa74d5ad166392590e72676a34d01d7b763', // ekubo router
    ],
  })

  // Wait for transaction
  const network = getNetwork(process.env.STARKNET_NETWORK)
  console.log('Tx hash: '.green, `${network.explorer_url}/tx/${contract.transaction_hash})`)
  await account.waitForTransaction(contract.transaction_hash)

  return contract.address
}

export const deployFactory = async (lockManagerAddress, ekuboLauncherAddress) => {
  // Load account
  const account = getAccount()

  // Declare contracts
  const memecoin = await declare(getUnruggableMemecoinPath(), 'UnruggableMemecoin')
  const factory = await declare(getFactoryPath(), 'Factory')

  // Deploy factory
  const exchanges = getExchanges(process.env.STARKNET_NETWORK)
  console.log(`\nDeploying Factory...`.green)
  console.log('Owner: '.green, process.env.STARKNET_ACCOUNT_ADDRESS)
  console.log('Memecoin class hash: '.green, memecoin.class_hash)
  console.log('Exchanges: '.green, exchanges)

  const contract = await account.deployContract({
    classHash: factory.class_hash,
    constructorCalldata: [memecoin.class_hash, lockManagerAddress, 1, 1, ekuboLauncherAddress, []],
  })

  // Wait for transaction
  const network = getNetwork(process.env.STARKNET_NETWORK)
  console.log('Tx hash: '.green, `${network.explorer_url}/tx/${contract.transaction_hash})`)
  await account.waitForTransaction(contract.transaction_hash)
}
