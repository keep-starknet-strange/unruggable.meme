import { useAccount, useProvider } from '@starknet-react/core'
import { useCallback, useEffect, useMemo, useState } from 'react'
import { FACTORY_ADDRESSES, MULTICALL_ADDRESS } from 'src/constants/contracts'
import { AMM, LIQUIDITY_LOCK_FOREVER_TIMESTAMP, LiquidityType, Selector } from 'src/constants/misc'
import { CallData, getChecksumAddress, hash, shortString, uint256 } from 'starknet'

import useChainId from './useChainId'
import { useDeploymentStore } from './useDeployment'

interface BaseMemecoinInfos {
  address: string
  name: string
  symbol: string
  totalSupply: string
  isLaunched: boolean
  isOwner: boolean
  owner: string
}

interface LaunchedMemecoin extends BaseMemecoinInfos {
  isLaunched: true
  launch: {
    blockNumber: number
    liquidityType: LiquidityType
    liquidityLockManager: string
    liquidityLockPosition?: string
    quoteToken: string
    quoteAmount?: string
    teamAllocation: string
  }
}

export interface NotLaunchedMemecoin extends BaseMemecoinInfos {
  isLaunched: false
  launch: undefined
}

export type MemecoinInfos = LaunchedMemecoin | NotLaunchedMemecoin

interface LockPosition {
  unlockTime: number
}

export function useMemecoinInfos() {
  const [memecoinInfos, setMemecoinInfos] = useState<Omit<MemecoinInfos, 'isOwner'> | undefined>()
  const [error, setError] = useState<string | undefined>()
  const [indexing, setIndexing] = useState<boolean>(false)

  const { deployedTokenContracts } = useDeploymentStore()

  // starknet
  const { address } = useAccount()
  const { provider } = useProvider()
  const chainId = useChainId()

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
        selector: hash.getSelector(Selector.IS_LAUNCHED),
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

      const ownerCalldata = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.OWNER),
        calldata: [],
      })

      const lockedLiquidity = CallData.compile({
        to: FACTORY_ADDRESSES[chainId],
        selector: hash.getSelector(Selector.LOCKED_LIQUIDITY),
        calldata: [tokenAddress],
      })

      const launchBlock = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.LAUNCHED_AT_BLOCK_NUMBER),
        calldata: [],
      })

      const launchParams = CallData.compile({
        to: tokenAddress,
        selector: hash.getSelector(Selector.LAUNCHED_WITH_LIQUIDITY_PARAMETERS),
        calldata: [],
      })

      try {
        const res = await provider?.callContract({
          contractAddress: MULTICALL_ADDRESS,
          entrypoint: Selector.AGGREGATE,
          calldata: [
            10,
            ...isMemecoinCalldata,
            ...nameCalldata,
            ...symbolCalldata,
            ...launchedCalldata,
            ...totalSupplyCalldata,
            ...teamAllocationCalldata,
            ...ownerCalldata,
            ...lockedLiquidity,
            ...launchBlock,
            ...launchParams,
          ],
        })

        const isUnruggable = !!+res.result[3] // beautiful

        if (!isUnruggable) {
          setError('Not unruggable')
          return
        }

        const hasLiquidity = !+res.result[19] // even more beautiful
        const hasLaunchParams = !+res.result[26] // I'm delighted
        const launchedOn = hasLaunchParams ? Object.values(AMM)[+res.result[27]] : null

        const isLaunched = !!+res.result[9] && !!launchedOn && hasLiquidity && hasLaunchParams // meh...

        const launchInfos = isLaunched
          ? {
              teamAllocation: uint256.uint256ToBN({ low: res.result[14], high: res.result[15] }).toString(),
              liquidityLockManager: res.result[20] as string,
              liquidityType: Object.values(LiquidityType)[+res.result[21]] as LiquidityType,
              blockNumber: +res.result[24],

              ...(() => {
                switch (launchedOn) {
                  case AMM.JEDISWAP:
                    return {
                      liquidityLockPosition: res.result[31],
                      quoteToken: getChecksumAddress(res.result[28]),
                      quoteAmount: uint256.uint256ToBN({ low: res.result[29], high: res.result[30] }).toString(),
                    }

                  case AMM.EKUBO:
                    return {
                      quoteToken: '0xdead',
                    }
                }
              })(),
            }
          : undefined

        const baseMemecoinInfos = {
          address: tokenAddress,
          name: shortString.decodeShortString(res.result[5]),
          symbol: shortString.decodeShortString(res.result[7]),
          totalSupply: uint256.uint256ToBN({ low: res.result[11], high: res.result[12] }).toString(),
          owner: getChecksumAddress(res.result[17]),
          isLaunched,
        }

        setMemecoinInfos({ ...baseMemecoinInfos, launch: launchInfos })
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
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [chainId, provider, deployedTokenContracts.length]
  )

  // reset state
  useEffect(() => {
    setMemecoinInfos(undefined)
    setError(undefined)
  }, [])

  // isOwner
  const isOwner = useMemo(
    () => (memecoinInfos && address ? getChecksumAddress(address) === memecoinInfos.owner : false),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [address, memecoinInfos?.owner]
  )

  return [
    { data: memecoinInfos ? ({ ...memecoinInfos, isOwner } as MemecoinInfos) : undefined, error, indexing },
    getMemecoinInfos,
  ] as const
}

export function useMemecoinliquidityLockPosition(
  liquidityType?: LiquidityType,
  lockManager?: string,
  lockPosition?: string
) {
  const [liquidity, setLiquidity] = useState<LockPosition | undefined>()

  // starknet
  const { provider } = useProvider()
  const chainId = useChainId()

  useEffect(() => {
    if (!lockManager || liquidityType === undefined || !chainId) {
      setLiquidity(undefined)
      return
    }

    switch (liquidityType) {
      case LiquidityType.ERC20: {
        if (!lockPosition) {
          setLiquidity(undefined)
          return
        }

        provider
          ?.callContract({
            contractAddress: lockManager,
            entrypoint: Selector.GET_LOCK_DETAILS,
            calldata: [lockPosition],
          })
          .then((res) => {
            setLiquidity({
              unlockTime: +res?.result[4],
            })
          })

        break
      }

      case LiquidityType.NFT: {
        setLiquidity({
          unlockTime: LIQUIDITY_LOCK_FOREVER_TIMESTAMP,
        })
      }
    }
  }, [lockManager, lockPosition, liquidityType, chainId, provider])

  return liquidity
}
