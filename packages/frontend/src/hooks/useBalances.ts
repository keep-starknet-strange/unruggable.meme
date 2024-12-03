import { useAccount, useReadContract, UseReadContractResult } from '@starknet-react/core'
import { Fraction } from '@uniswap/sdk-core'
import { Token } from 'core'
import { compiledMulticall, Entrypoint, MULTICALL_ADDRESSES } from 'core/constants'
import { useMemo } from 'react'
import { decimalsScale } from 'src/utils/decimals'
import { CallStruct, selector, uint256 } from 'starknet'

import useChainId from './useChainId'

type Balance = Fraction
type Balances = Record<string, Balance>

interface UseBalancesResult extends Pick<UseReadContractResult<any, any>, 'error' | 'refetch'> {
  data?: Balances
  loading: boolean
}

type UseBalancesToken = Pick<Token, 'address' | 'camelCased' | 'decimals'>

// eslint-disable-next-line import/no-unused-modules
export default function useBalances(tokens: UseBalancesToken[]): UseBalancesResult {
  const { address: accountAddress } = useAccount()
  const chainId = useChainId()

  const res = useReadContract({
    abi: compiledMulticall, // call is not send if abi is undefined
    address: accountAddress && chainId ? MULTICALL_ADDRESSES[chainId] : undefined,
    functionName: 'aggregate',
    watch: true,
    args: [
      tokens.map(
        (token): CallStruct => ({
          to: token.address,
          selector: selector.getSelector(token.camelCased ? Entrypoint.BALANCE_OF_CAMEL : Entrypoint.BALANCE_OF),
          calldata: [accountAddress ?? ''],
        }),
      ),
    ],
  })

  const resData: [bigint, [bigint, bigint][]] | undefined = res.data

  const data = useMemo(() => {
    if (!resData) return undefined

    return resData[1].reduce<Record<string, Fraction>>((acc, balance, index) => {
      const token = tokens[index]
      acc[token.address] = new Fraction(
        uint256.uint256ToBN({ low: balance[0], high: balance[1] }).toString(),
        decimalsScale(token.decimals),
      )

      return acc
    }, {})
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [resData?.[0].toString()])

  return { data, loading: res.fetchStatus === 'fetching', error: res.error, refetch: res.refetch }
}

export function useBalance(token?: UseBalancesToken) {
  const { data: balances, ...rest } = useBalances(token ? [token] : [])

  const tokenBalance = useMemo(() => (balances && token ? balances[token.address] : undefined), [balances, token])

  return { ...rest, data: tokenBalance }
}
