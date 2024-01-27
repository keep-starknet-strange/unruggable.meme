import { QUOTE_TOKENS, TokenInfos } from 'src/constants/contracts'
import { constants } from 'starknet'

type QuoteTokenInfos = { safe: false } | ({ safe: true } & TokenInfos)

export function getQuoteTokenInfos(
  chainId?: constants.StarknetChainId,
  quoteAddress?: string
): QuoteTokenInfos | undefined {
  if (!quoteAddress || !chainId) return

  const quoteTokenInfos = QUOTE_TOKENS[chainId][quoteAddress]

  return {
    safe: !!quoteTokenInfos,
    ...quoteTokenInfos,
  }
}
