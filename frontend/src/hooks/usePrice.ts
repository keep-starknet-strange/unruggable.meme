import { useContractRead, UseContractReadResult } from '@starknet-react/core'
import { Fraction } from '@uniswap/sdk-core'
import { useMemo } from 'react'
import { compiledJediswapPair, JEDISWAP_ETH_USDC } from 'src/constants/contracts'
import { decimalsScale } from 'src/utils/decimalScale'
import { constants, Uint256, uint256 } from 'starknet'

import useChainId from './useChainId'

export function useEtherPrice() {
  const chainId = useChainId()

  const pairReserves = useContractRead({
    abi: compiledJediswapPair, // call is not send if abi is undefined
    address: chainId ? JEDISWAP_ETH_USDC[chainId] : undefined,
    functionName: 'get_reserves',
    watch: true,
  }) as UseContractReadResult & { data?: { reserve0: Uint256; reserve1: Uint256 } }

  return useMemo(() => {
    if (!pairReserves.data) return

    const ethPrice = new Fraction(
      uint256.uint256ToBN(pairReserves.data.reserve1).toString(),
      uint256.uint256ToBN(pairReserves.data.reserve0).toString()
    )

    // token0 and token1 are switched on goerli and mainnet ...
    return (
      chainId === constants.StarknetChainId.SN_GOERLI
        ? new Fraction(ethPrice.denominator, ethPrice.numerator)
        : ethPrice
    ).multiply(decimalsScale(12))
  }, [chainId, pairReserves.data])
}
