import { starknetChainId, useNetwork, useProvider } from '@starknet-react/core'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { FACTORY_ADDRESSES, MULTICALL_ADDRESS } from 'src/constants/contracts'
import { Selector } from 'src/constants/misc'
import { CallData, getChecksumAddress, hash, shortString, uint256 } from 'starknet'

import { useDeploymentStore } from './useDeployment'

interface MemecoinInfos {
  address: string
  name: string
  symbol: string
  maxSupply: string
  teamAllocation: string
  launched: boolean
}

export function useMemecoinInfos() {
  const [memecoinInfos, setMemecoinInfos] = useState<MemecoinInfos | undefined>()
  const [error, setError] = useState<string | undefined>()
  const [indexing, setIndexing] = useState<boolean>(false)

  const { deployedTokenContracts } = useDeploymentStore()

  // starknet
  const { chain } = useNetwork()
  const { provider } = useProvider()
  const chainId = useMemo(() => (chain.id ? starknetChainId(chain.id) : undefined), [chain.id])

  // getter
  const getMemecoinInfos = useCallback(
    async (tokenAddress: string) => {
      if (!chainId) return

      setError(undefined)

      const isMemecoinCalldata = CallData.compile({
        to: FACTORY_ADDRESSES[chainId],
        selector: hash.getSelector(Selector.IS_MEMECOIN),
        calldata: [tokenAddress],
      })

      const nameCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.NAME),
        calldata: [],
      })

      const symbolCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.SYMBOL),
        calldata: [],
      })

      const launchedCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.LAUNCHED),
        calldata: [],
      })

      const totalSupplyCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.TOTAL_SUPPLY),
        calldata: [],
      })

      const teamAllocationCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.GET_TEAM_ALLOCATION),
        calldata: [],
      })

      try {
        const res = await provider?.callContract({
          contractAddress: MULTICALL_ADDRESS,
          entrypoint: Selector.AGGREGATE,
          calldata: [
            6,
            ...isMemecoinCalldata,
            ...nameCalldata,
            ...symbolCalldata,
            ...launchedCalldata,
            ...totalSupplyCalldata,
            ...teamAllocationCalldata,
          ],
        })

        const isUnruggable = !!+res.result[3] // beautiful

        if (!isUnruggable) {
          setError('Not unruggable')
        }

        const memecoinInfos = {
          address: tokenAddress,
          name: shortString.decodeShortString(res.result[5]),
          symbol: shortString.decodeShortString(res.result[7]),
          launched: !!+res.result[9],
          maxSupply: uint256.uint256ToBN({ low: res.result[11], high: res.result[12] }).toString(),
          teamAllocation: uint256.uint256ToBN({ low: res.result[14], high: res.result[15] }).toString(),
        }

        setMemecoinInfos(memecoinInfos)

        return memecoinInfos // still return memecoin infos
      } catch (err) {
        // might just not be already indexed
        for (const deployedTokenContract of deployedTokenContracts) {
          if (getChecksumAddress(deployedTokenContract.address) === getChecksumAddress(tokenAddress)) {
            setIndexing(true)
            return
          }
        }

        setError('Not unruggable')
      }

      return
    },
    [chainId, provider, deployedTokenContracts]
  )

  // reset state
  useEffect(() => {
    setMemecoinInfos(undefined)
    setError(undefined)
  }, [])

  return [{ data: memecoinInfos, error, indexing }, getMemecoinInfos] as const
}
