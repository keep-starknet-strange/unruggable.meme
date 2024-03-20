import { useContractRead, UseContractReadResult } from '@starknet-react/core'
import { Fraction } from '@uniswap/sdk-core'
import { useCallback, useMemo } from 'react'
import { compiledJediswapPair, JEDISWAP_ETH_USDC, JEDISWAP_STRK_USDC } from 'src/constants/contracts'
import { Selector } from 'src/constants/misc'
import { decimalsScale } from 'src/utils/decimalScale'
import { BlockNumber, BlockTag, constants, getChecksumAddress, Uint256, uint256 } from 'starknet'

import useChainId from './useChainId'
import useQuoteToken from './useQuote'

function usePairPrice(pairAddress?: string, blockIdentifier: BlockNumber = BlockTag.latest) {
  const chainId = useChainId()

  const pairReserves = useContractRead({
    abi: compiledJediswapPair, // call is not send if abi is undefined
    address: pairAddress,
    functionName: Selector.GET_RESERVES,
    watch: true,
    blockIdentifier,
  }) as UseContractReadResult & { data?: { reserve0: Uint256; reserve1: Uint256 } }

  return useMemo(() => {
    if (!pairReserves.data) return

    const pairPrice = new Fraction(
      uint256.uint256ToBN(pairReserves.data.reserve1).toString(),
      uint256.uint256ToBN(pairReserves.data.reserve0).toString()
    )

    // token0 and token1 are switched on goerli and mainnet ...
    return (
      chainId === constants.StarknetChainId.SN_GOERLI
        ? new Fraction(pairPrice.denominator, pairPrice.numerator)
        : pairPrice
    ).multiply(decimalsScale(12))
  }, [chainId, pairReserves.data])
}

function useEtherPrice(blockIdentifier: BlockNumber = BlockTag.latest) {
  const chainId = useChainId()

  return usePairPrice(chainId ? JEDISWAP_ETH_USDC[chainId] : undefined, blockIdentifier)
}

function useStarkPrice(blockIdentifier: BlockNumber = BlockTag.latest) {
  const chainId = useChainId()

  return usePairPrice(chainId ? JEDISWAP_STRK_USDC[chainId] : undefined, blockIdentifier)
}

export function useQuoteTokenPrice(quoteTokenAddress?: string, blockIdentifier: BlockNumber = BlockTag.latest) {
  const etherPrice = useEtherPrice(blockIdentifier)
  const starkPrice = useStarkPrice(blockIdentifier)
  const usdcPrice = new Fraction(1, 1)

  const quoteToken = useQuoteToken(quoteTokenAddress ? getChecksumAddress(quoteTokenAddress) : undefined)
  if (!quoteToken) return

  return {
    ETH: etherPrice,
    STRK: starkPrice,
    USDC: usdcPrice,
  }[quoteToken.symbol]

  return
}

export function useWeiAmountToParsedFiatValue(price?: Fraction): (amount?: Fraction) => string | null {
  return useCallback(
    (amount?: Fraction) =>
      price && amount
        ? `$${(Math.round(+amount.multiply(price).toFixed(6) * 100) / 100).toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}`
        : null,
    [price]
  )
}
