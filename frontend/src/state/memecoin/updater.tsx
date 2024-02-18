import { useProvider } from '@starknet-react/core'
import { useCallback, useEffect } from 'react'
import { FACTORY_ADDRESSES, MULTICALL_ADDRESS } from 'src/constants/contracts'
import { LIQUIDITY_LOCK_FOREVER_TIMESTAMP, LiquidityType, Selector } from 'src/constants/misc'
import useChainId from 'src/hooks/useChainId'
import { CallData, getChecksumAddress, hash, shortString, uint256 } from 'starknet'

import { useBoundStore } from '..'
import { EkuboMemecoin, JediswapMemecoin } from '.'

// eslint-disable-next-line import/no-unused-modules
export default function MemecoinUpdater(): null {
  // store
  const { needsMemecoinRefresh, tokenAddress, setRuggable, setMemecoin, startRefresh } = useBoundStore((state) => ({
    needsMemecoinRefresh: state.needsMemecoinRefresh,
    tokenAddress: state.tokenAddress,
    setRuggable: state.setRuggable,
    setMemecoin: state.setMemecoin,
    startRefresh: state.startRefresh,
  }))

  // starknet
  const { provider } = useProvider()
  const chainId = useChainId()

  // liquidity lock position
  const { getMemecoinEkuboLiquidityLockPosition, getMemecoinJediswapLiquidityLockPosition } =
    useGetMemecoinLiquidityLockPosition()

  // fetch callback
  const fetchMemecoin = useCallback(async () => {
    if (!tokenAddress || !chainId) return

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
        setRuggable()
        return
      }

      const hasLiquidity = !+res.result[19] // even more beautiful
      const hasLaunchParams = !+res.result[26] // I'm delighted

      const isLaunched = !!+res.result[9] && hasLiquidity && hasLaunchParams // meh...

      const baseMemecoin = {
        address: tokenAddress,
        name: shortString.decodeShortString(res.result[5]),
        symbol: shortString.decodeShortString(res.result[7]),
        totalSupply: uint256.uint256ToBN({ low: res.result[11], high: res.result[12] }).toString(),
        owner: getChecksumAddress(res.result[17]),
      }

      if (isLaunched) {
        const launch = {
          teamAllocation: uint256.uint256ToBN({ low: res.result[14], high: res.result[15] }).toString(),
          blockNumber: +res.result[24],
        }

        const liquidityType = Object.values(LiquidityType)[+res.result[21]] as LiquidityType

        const lockManager = res.result[20] as string

        switch (liquidityType) {
          case LiquidityType.ERC20: {
            const liquidity = {
              type: LiquidityType.ERC20,
              lockManager,
              lockPosition: res.result[31],
              quoteToken: getChecksumAddress(res.result[28]),
              quoteAmount: uint256.uint256ToBN({ low: res.result[29], high: res.result[30] }).toString(),
            } as const

            setMemecoin({
              ...baseMemecoin,
              isLaunched: true,
              launch,
              liquidity: {
                ...liquidity,
                ...(await getMemecoinJediswapLiquidityLockPosition(liquidity)),
              },
            })
            break
          }

          case LiquidityType.NFT: {
            const liquidity = {
              type: LiquidityType.NFT,
              lockManager,
              ekuboId: res.result[22],
              quoteToken: getChecksumAddress(res.result[33]),
              startingTick: +res.result[30] * (+res.result[31] ? -1 : 1), // mag * sign
            } as const

            setMemecoin({
              ...baseMemecoin,
              isLaunched: true,
              launch,
              liquidity: {
                ...liquidity,
                ...(await getMemecoinEkuboLiquidityLockPosition(liquidity)),
              },
            })
          }
        }
      } else {
        setMemecoin({ ...baseMemecoin, isLaunched: false })
      }
    } catch {
      setRuggable()
    }
  }, [
    chainId,
    getMemecoinEkuboLiquidityLockPosition,
    getMemecoinJediswapLiquidityLockPosition,
    provider,
    setMemecoin,
    setRuggable,
    tokenAddress,
  ])

  // refresher
  useEffect(() => {
    if (needsMemecoinRefresh) {
      startRefresh()
      fetchMemecoin()
    }
  }, [fetchMemecoin, needsMemecoinRefresh, startRefresh])

  return null
}

//
// LIQUIDITY
//

function useGetMemecoinLiquidityLockPosition() {
  // starknet
  const { provider } = useProvider()

  const getMemecoinJediswapLiquidityLockPosition = useCallback(
    async (liquidity: Pick<JediswapMemecoin['liquidity'], 'lockPosition' | 'lockManager'>) => {
      return provider
        ?.callContract({
          contractAddress: liquidity.lockManager,
          entrypoint: Selector.GET_LOCK_DETAILS,
          calldata: [liquidity.lockPosition],
        })
        .then((res) => {
          return {
            unlockTime: +res.result[4],
            owner: res.result[3],
          }
        })
    },
    [provider]
  )

  const getMemecoinEkuboLiquidityLockPosition = useCallback(
    async (liquidity: Pick<EkuboMemecoin['liquidity'], 'ekuboId' | 'lockManager'>) => {
      return provider
        ?.callContract({
          contractAddress: liquidity.lockManager,
          entrypoint: Selector.LIQUIDITY_POSITION_DETAILS,
          calldata: [liquidity.ekuboId],
        })
        .then((res) => {
          return {
            unlockTime: LIQUIDITY_LOCK_FOREVER_TIMESTAMP,
            owner: res.result[0],
            // pool key
            poolKey: {
              token0: res.result[2],
              token1: res.result[3],
              fee: res.result[4],
              tickSpacing: res.result[5],
              extension: res.result[6],
            },
            bounds: {
              lower: {
                mag: res.result[7],
                sign: res.result[8],
              },
              upper: {
                mag: res.result[9],
                sign: res.result[10],
              },
            },
          }
        })
    },
    [provider]
  )

  return { getMemecoinJediswapLiquidityLockPosition, getMemecoinEkuboLiquidityLockPosition }
}
