import { fetchBuildExecuteTransaction, fetchQuotes, Quote, QuoteRequest } from '@avnu/avnu-sdk'
import { useAccount, useBlockNumber } from '@starknet-react/core'
import { useCallback, useEffect, useState } from 'react'
import { getAvnuOptions } from 'src/utils/avnu'
import { Call } from 'starknet'

export function useGetAvnuQuotes(
  tokenAddressFrom: string,
  tokenAddressTo: string,
  amount: string | number,
): Quote | null {
  const account = useAccount()

  const [quote, setQuote] = useState<Quote | null>(null)

  const { data: blockNumber } = useBlockNumber({ refetchInterval: 3000 })

  useEffect(() => {
    if (!blockNumber) return

    const AVNU_OPTIONS = getAvnuOptions(account.chainId)

    const abortController = new AbortController()

    const params: QuoteRequest = {
      sellTokenAddress: tokenAddressFrom,
      buyTokenAddress: tokenAddressTo,
      sellAmount: BigInt(amount),
    }

    fetchQuotes(params, { ...AVNU_OPTIONS, abortSignal: abortController.signal })
      .then((quotes) => {
        setQuote(quotes.length > 0 ? quotes[0] : null)
      })
      .catch((error) => {
        if (!abortController.signal.aborted) {
          console.log(error)
        }
      })

    return () => abortController.abort()
  }, [account.chainId, tokenAddressFrom, tokenAddressTo, amount, blockNumber])

  return quote
}

export function useAvnuSwapBuilder(slippage: number): (quote: Quote) => Promise<Call[] | undefined> {
  const account = useAccount()

  return useCallback(
    async (quote: Quote) => {
      if (!account.address) return

      const AVNU_OPTIONS = getAvnuOptions(account.chainId)

      const { calls } = await fetchBuildExecuteTransaction(
        quote.quoteId,
        account.address,
        slippage / 10_000,
        true,
        AVNU_OPTIONS,
      )
      return calls
    },
    [account.address, account.chainId, slippage],
  )
}
