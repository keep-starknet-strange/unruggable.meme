/* eslint-disable import/no-unused-modules */
import { Factory } from 'core'
import { constants, RpcProvider } from 'starknet'
import { Config, CreateMemecoinParameters } from './types'



export async function createMemecoin(config: Config, parameters: CreateMemecoinParameters) {
    const factory = new Factory({ provider: config.starknetProvider, chainId: constants.StarknetChainId.SN_MAIN })

   /*  try {
        await factory.getMemecoin('0x')
    } catch (e) {
        console.log('Error: shit happened')
    } */

    console.log('create memecoin')
}
