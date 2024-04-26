import { useAccount } from '@starknet-react/core'
import { useCallback, useEffect, useMemo } from 'react'
import { useBoundStore } from 'src/state'
import { getChecksumAddress } from 'starknet'

export default function useMemecoin(tokenAddress?: string) {
  // store
  const { memecoin, refreshMemecoin, setTokenAddress, ruggable, resetMemecoin } = useBoundStore((state) => ({
    memecoin: state.memecoin,
    refreshMemecoin: state.refreshMemecoin,
    setTokenAddress: state.setTokenAddress,
    ruggable: state.ruggable,
    resetMemecoin: state.resetMemecoin,
  }))

  // set token address
  useEffect(() => {
    if (tokenAddress) {
      setTokenAddress(tokenAddress)
    }
  }, [tokenAddress, setTokenAddress])

  // starknet
  const { address } = useAccount()

  // isOwner
  const isOwner = useMemo(() => {
    if (!address || !memecoin) return false

    const checksummedAddress = getChecksumAddress(address)

    if (memecoin.isLaunched) {
      return getChecksumAddress(memecoin.liquidity.owner) === checksummedAddress
    } else {
      return getChecksumAddress(memecoin.owner) === checksummedAddress
    }
  }, [address, memecoin])

  // refresh
  const refresh = useCallback(
    (tokenAddress?: string) => {
      if (tokenAddress) {
        setTokenAddress(tokenAddress)
      } else {
        refreshMemecoin()
      }
    },
    [refreshMemecoin, setTokenAddress],
  )

  // reset
  useEffect(() => {
    if (tokenAddress) {
      return resetMemecoin
    }

    return
  }, [tokenAddress, resetMemecoin])

  return { data: memecoin ? { ...memecoin, isOwner } : null, ruggable, refresh }
}
