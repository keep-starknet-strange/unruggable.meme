import QRCode from 'qrcode'
import { constants } from 'starknet'

import { Adapters } from '../adapters'
import { BaseAdapter } from '../adapters/BaseAdapter'
import { adapterStorage } from '../utils/storage'
import { bot } from './bot'

const callbacks: Record<number, (adapter: BaseAdapter, accounts: string[]) => void | Promise<void> | undefined> = {}

export const useWallet = async (
  chatId: number,
  onConnect: (adapter: BaseAdapter, accounts: string[]) => void | Promise<void>,
): Promise<void> => {
  if (!chatId) return

  const existing = adapterStorage.getAdapter(chatId)
  if (existing && existing.connected) {
    onConnect(existing, existing.accounts)
    return
  }

  callbacks[chatId] = onConnect

  bot.sendMessage(chatId, 'Please choose your wallet', {
    reply_markup: {
      inline_keyboard: [
        [
          {
            text: 'Cancel',
            callback_data: 'wallet_cancel',
          },
        ],
        ...Object.entries(Adapters).map(([key, adapter]) => [
          {
            text: adapter.name,
            callback_data: `wallet_${key}`,
          },
        ]),
      ],
    },
  })
}

bot.on('callback_query', async (query) => {
  if (!query.message || !query.data) return

  const chatId = query.message.chat.id
  const onConnect = callbacks[chatId]

  if (!onConnect || !query.data || !query.data.startsWith('wallet_')) return

  const data = query.data?.replace('wallet_', '')

  if (!['cancel', ...Object.keys(Adapters)].includes(data)) {
    bot.sendMessage(chatId, 'Invalid wallet selected. Please try again.')
    return
  }

  bot.deleteMessage(chatId, query.message.message_id)
  delete callbacks[chatId]

  if (data === 'cancel') {
    bot.sendMessage(chatId, 'Connection cancelled.')
    return
  }

  const adapter = data as keyof typeof Adapters

  try {
    const Adapter = Adapters[adapter].adapter
    const newAdapter = new Adapter({ chain: constants.NetworkName.SN_MAIN, chatId })
    await newAdapter.init()

    adapterStorage.addAdapter(chatId, newAdapter)

    newAdapter.onDisconnect(() => {
      adapterStorage.removeAdapter(chatId)
    })

    const connectResult = await newAdapter.connect()
    if ('error' in connectResult) {
      adapterStorage.removeAdapter(chatId)
      // No need to send a message here, this error is only can be user rejected or timeout
      return
    }

    if ('skipConnection' in connectResult) {
      onConnect(newAdapter, newAdapter.accounts)
      return
    }

    const { qrUrl, buttonUrl, waitForApproval } = connectResult

    const qrBuffer = await QRCode.toBuffer(qrUrl, { width: 256 })

    const connectMsg = await bot.sendPhoto(
      chatId,
      qrBuffer,
      {
        caption: 'Scan the QR code or click the button below to connect your wallet',
        reply_markup: {
          inline_keyboard: [
            [
              {
                text: 'Click To Connect',
                url: buttonUrl,
              },
            ],
          ],
        },
      },
      {
        filename: 'connect_qr',
        contentType: 'image/png',
      },
    )

    const result = await waitForApproval()

    if ('error' in result) {
      switch (result.error) {
        case 'no_accounts_connected':
          bot.sendMessage(chatId, 'No accounts connected to wallet')
          break

        case 'wrong_chain':
          bot.sendMessage(chatId, 'Wrong chain selected. Please switch to Starknet Mainnet')
          break

        case 'unknown_error':
          bot.sendMessage(chatId, 'Failed to connect to wallet')
          break
      }

      adapterStorage.removeAdapter(chatId)
      bot.deleteMessage(connectMsg.chat.id, connectMsg.message_id)
      return
    }

    const { accounts } = result

    bot.sendMessage(chatId, `Connected to wallet with account: ${accounts[0]}`)
    bot.deleteMessage(connectMsg.chat.id, connectMsg.message_id)
    onConnect(newAdapter, accounts)
  } catch (e) {
    bot.sendMessage(chatId, 'Failed to connect to wallet')
  }
})
