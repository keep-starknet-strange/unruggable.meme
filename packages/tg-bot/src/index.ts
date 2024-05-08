/* eslint-disable simple-import-sort/imports */

import 'dotenv/config'

import { bot, botInfo } from './services/bot'

// ************ COMMANDS ************

import './commands/start'
import './commands/unrug'
import './commands/deploy'
import './commands/launch'

// ************ BOT INFO ************

const start = {
  command: 'start',
  description: 'Starts the bot',
}

const unrug = {
  command: 'unrug',
  description: 'Checks if a token is unruggable. Usage: /unrug [token_address]',
}

const deploy = {
  command: 'deploy',
  description: 'Deploys a new meme coin.',
}

const launch = {
  command: 'launch',
  description: 'Launches a deployed meme coin.',
}

;(async () => {
  await bot.setMyCommands([start, unrug], { scope: { type: 'default' } })
  await bot.setMyCommands([start, unrug, deploy, launch], { scope: { type: 'all_private_chats' } })

  const me = await bot.getMe()

  botInfo.id = me.id
  botInfo.username = me.username ?? ''

  console.log('Bot is running...')
})()
