import { bot } from '../services/bot'

bot.onText(/\/start/, async (msg): Promise<void> => {
  await bot.sendMessage(msg.chat.id, `Hello, You can use /unrug command to check if a token is unrugabble or not.`)
})
