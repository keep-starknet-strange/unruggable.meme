import { Percent } from '@uniswap/sdk-core'
import { getPairPrice } from 'core'

import { bot } from '../services/bot'
import { factory } from '../services/factory'
import { formatPercentage, isValidStarknetAddress } from '../utils/helpers'

// Matches "/unrug [token_address]"
bot.onText(/\/unrug/, (msg) => {
  // 'msg' is the received Message from Telegram
  // 'match' is the result of executing the regexp above on the text content
  // of the message

  const chatId = msg.chat.id
  const tokenAddress = msg.text?.split(' ')[1] // the captured "token_address"

  if (!tokenAddress) {
    bot.sendMessage(msg.chat.id, 'Usage: /unrug [token_address]')
    return
  }

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
      const memecoin = await factory.getMemecoin(tokenAddress)

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

        // quote token
        if (!memecoin.quoteToken) {
          return 'This token is Ruggable ❌ (unknown quote token)'
        }

        // usdc pair price at launch
        const pairPriceAtLaunch = await getPairPrice(
          factory.config.provider,
          memecoin.quoteToken.usdcPair,
          memecoin.launch.blockNumber,
        )

        // starting mcap
        const startingMcap = factory.getStartingMarketCap(memecoin, pairPriceAtLaunch)
        const parsedStartingMcap = startingMcap ? `$${startingMcap.toFixed(0, { groupSeparator: ',' })}` : 'UNKNOWN'

        response += `Starting mcap: ${parsedStartingMcap}\n`
      }

      return response
    } catch (_err) {
      return 'This token is Ruggable ❌'
    }
  }
}
