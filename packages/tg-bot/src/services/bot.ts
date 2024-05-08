import TelegramBot from 'node-telegram-bot-api'

// replace the value below with the Telegram token you receive from @BotFather
const telegramBotToken = process.env.TELEGRAM_BOT_TOKEN

// Exit if the token is not provided
if (!telegramBotToken) {
  console.error('TELEGRAM_BOT_TOKEN is not provided')
  process.exit(1)
}

export const bot = new TelegramBot(telegramBotToken, { polling: true })

export const botInfo = {
  id: -1,
  username: '',
}
