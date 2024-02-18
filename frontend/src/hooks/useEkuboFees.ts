import { useContractRead, UseContractReadResult } from '@starknet-react/core'
import { Fraction } from '@uniswap/sdk-core'
import { useMemo } from 'react'
import { compiledEkuboPositions, EKUBO_POSITIONS_ADDRESSES } from 'src/constants/contracts'
import { LiquidityType, Selector } from 'src/constants/misc'
import { decimalsScale } from 'src/utils/decimals'
import { CallData } from 'starknet'

import useChainId from './useChainId'
import useMemecoin from './useMemecoin'
import useQuoteToken from './useQuote'

export default function useEkuboFees() {
  // memecoin
  const { data: memecoin } = useMemecoin()

  // quote token
  const quoteToken = useQuoteToken(memecoin?.isLaunched ? memecoin.liquidity.quoteToken : undefined)

  // can collect
  const calldata = useMemo(() => {
    if (!memecoin?.isLaunched || memecoin.liquidity.type !== LiquidityType.NFT) return

    return CallData.compile([memecoin.liquidity.ekuboId, memecoin.liquidity.poolKey, memecoin.liquidity.bounds])
  }, [memecoin])

  // starknet
  const chainId = useChainId()

  const { data } = useContractRead({
    abi: calldata ? compiledEkuboPositions : undefined, // call is not send if abi is undefined
    address: chainId ? EKUBO_POSITIONS_ADDRESSES[chainId] : undefined,
    functionName: Selector.GET_TOKEN_INFOS,
    watch: true,
    args: calldata,
  }) as UseContractReadResult & { data?: { fees0: bigint; fees1: bigint } }

  return useMemo(() => {
    if (data?.fees0 === undefined || !memecoin?.isLaunched || !chainId || !quoteToken?.decimals) return

    return new Fraction(
      (new Fraction(memecoin.address).lessThan(memecoin.liquidity.quoteToken) ? data.fees1 : data.fees0).toString(),
      decimalsScale(quoteToken.decimals)
    )
  }, [data?.fees0, data?.fees1, memecoin, chainId, quoteToken?.decimals])
}
