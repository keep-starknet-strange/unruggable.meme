import { CallData, constants, hash, RpcProvider } from 'starknet'

import { MULTICALL_ADDRESSES, Selector } from '../constants'

export async function multiCallContract(
  provider: RpcProvider,
  chainId: constants.StarknetChainId,
  calls: {
    to: string
    selector: string
    calldata?: any[]
  }[]
) {
  const calldata = calls.map((call) => {
    return CallData.compile({
      to: call.to,
      selector: hash.getSelector(call.selector),
      calldata: call.calldata ?? [],
    })
  })

  const rawResult = await provider.callContract({
    contractAddress: MULTICALL_ADDRESSES[chainId],
    entrypoint: Selector.AGGREGATE,
    calldata: [calldata.length, ...calldata.flat()],
  })
  const raw = rawResult.result.slice(2)

  const result: string[][] = []
  let idx = 0

  for (let i = 0; i < raw.length; i += idx + 1) {
    idx = parseInt(raw[i], 16)

    result.push(raw.slice(i + 1, i + 1 + idx))
  }

  return result
}
