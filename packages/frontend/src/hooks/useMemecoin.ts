import { useAccount } from '@starknet-react/core'
import { useMemecoin as useSDKMemecoin } from 'hooks'
import { useMemo } from 'react'
import { getChecksumAddress } from 'starknet'

export default function useMemecoin(tokenAddress?: string) {
  // store
  // memecoin, refreshMemecoin, setTokenAddress, ruggable, resetMemecoin
  const memecoin = useSDKMemecoin({
    address: tokenAddress,
    watch: true,
  })

  // starknet
  const { address } = useAccount()

  // isOwner
  const isOwner = useMemo(() => {
    if (!address || !memecoin.data) return false

    const checksummedAddress = getChecksumAddress(address)

    if (memecoin.data.isLaunched) {
      return getChecksumAddress(memecoin.data.liquidity.owner) === checksummedAddress
    } else {
      return getChecksumAddress(memecoin.data.owner) === checksummedAddress
    }
  }, [address, memecoin])

  return {
    ...memecoin,

    data: memecoin.data ? { ...memecoin.data, isOwner } : null,
    ruggable: memecoin.isFetched && !memecoin.data,
    refresh: memecoin.refetch,
  }
}
