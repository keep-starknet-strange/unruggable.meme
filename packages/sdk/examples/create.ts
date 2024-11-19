import { createMemecoin, Config, launchOnEkubo } from '../src'
import { RpcProvider, Account } from 'starknet'
;(async () => {
  const starknetProvider = new RpcProvider({ nodeUrl: 'https://starknet-mainnet.public.blastapi.io' })

  const config: Config = {
    starknetProvider,
  }

  const starknetAccount = new Account(
    starknetProvider,
    process.env.ACCOUNT_ADDRESS || '',
    process.env.ACCOUNT_PRIVATE_KEY || '',
  )

  const result = await createMemecoin(config, {
    initialSupply: '1',
    name: 'R4MI',
    owner: '0x0416ba0f3d21eda5a87d05d0acc827075792132697e9ed973f4390808790a11a',
    starknetAccount,
    symbol: 'R4MI',
  })

  if (result) {
    const { tokenAddress, transactionHash } = result
    console.log(`Creating memecoin... Transaction hash: ${transactionHash} - Token Address: ${tokenAddress}`)
    await starknetProvider.waitForTransaction(transactionHash)

    const launchResult = await launchOnEkubo(config, {
      memecoinAddress: tokenAddress,
      starknetAccount,
      antiBotPeriodInSecs: 0,
      fees: '0.3',
      holdLimit: '1',
      startingMarketCap: '100000',
    })

    if (launchResult) {
      console.log(`Launching on Ekubo... Transaction hash: ${launchResult.transactionHash}`)
    }
  }
})()
