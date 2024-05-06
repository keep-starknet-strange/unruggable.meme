import 'dotenv/config'

import { bot } from './services/bot'

console.log('Bot is running...')

// ************ COMMANDS ************

import './commands/start'
import './commands/unrug'

// ************ BOT INFO ************

bot.setMyCommands(
  [
    {
      command: 'start',
      description: 'Starts the bot',
    },
    {
      command: 'unrug',
      description: 'Checks if a token is unruggable.\nUsage: /unrug [token_address]',
    },
  ],
  { scope: { type: 'default' } },
)
