import { dedent } from 'ts-dedent'

import { bot } from '../services/bot'
import { Forms } from '../utils/form'

bot.onText(/^\/start/, async (msg): Promise<void> => {
  Forms.resetForm(msg.chat.id)

  await bot.sendMessage(
    msg.chat.id,
    dedent`
      Hello, You can use /unrug command to check if a token is unrugabble or not.
      Or deploy a new memecoin using /deploy command.
    `.trim(),
  )
})
