import { Factory } from 'core'
import { constants } from 'starknet'

import { provider } from './provider'

export const factory = new Factory({ provider, chainId: constants.StarknetChainId.SN_MAIN })
