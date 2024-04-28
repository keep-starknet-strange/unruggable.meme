import { Percent } from '@uniswap/sdk-core'

import { bot } from '../services/bot'
import { isValidStarknetAddress } from '../utils/helpers'
import { parseLiquidityParams } from '../utils/liquidity'
import { getTokenData, parseTokenData } from '../utils/memecoinData'
import { formatPercentage } from '../utils/price'

// Matches "/unrug [token_address]"
bot.onText(/\/unrug (.+)/, (msg, match) => {
  // TODO: add usage
  if (!match?.[1]) return

  // 'msg' is the received Message from Telegram
  // 'match' is the result of executing the regexp above on the text content
  // of the message

  const chatId = msg.chat.id
  const tokenAddress = match[1] // the captured "token_address"

  computeResponse(chatId, tokenAddress).then((response) => {
    // handle response
    console.log(response)
    bot.sendMessage(chatId, response)
  })
})

async function computeResponse(chatId: number, tokenAddress: string): Promise<string> {
  // Check if the provided address is a valid StarnNet address
  if (!isValidStarknetAddress(tokenAddress)) {
    return `The provided address is a not valid Starknet address: ${tokenAddress}`
  } else {
    // Display loading message
    bot.sendMessage(chatId, 'Loading...')

    try {
      const rawMemecoin = await getTokenData(tokenAddress)
      const memecoin = await parseTokenData(tokenAddress, rawMemecoin)

      if (!memecoin) {
        return 'This token is Ruggable ❌'
      }

      let response =
        `This token IS Unruggable ✅\n\n` + `Token name: ${memecoin.name}\n` + `Token symbol: $${memecoin.symbol}\n`

      if (!memecoin.isLaunched) {
        response += '\nNot launched yet.'
      } else {
        // team allocation
        const teamAllocation = new Percent(memecoin.launch.teamAllocation, memecoin.totalSupply)
        const parsedTeamAllocation = formatPercentage(teamAllocation)

        response += `Team alloc: ${parsedTeamAllocation}\n`

        // Liquidity
        const { parsedStartingMcap, isQuoteTokenSafe } = await parseLiquidityParams(memecoin)
        if (!isQuoteTokenSafe) {
          return 'This token is Ruggable ❌ (unknown quote token)'
        }

        response += `Starting mcap: ${parsedStartingMcap}\n`
      }

      return response
    } catch (_err) {
      return 'This token is Ruggable ❌'
    }
  }
}
