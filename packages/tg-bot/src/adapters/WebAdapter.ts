import { constants } from 'starknet'

import { bot } from '../services/bot'
import {
  BaseAdapter,
  BaseAdapterConstructorOptions,
  ConnectReturnType,
  DisconnectReturnType,
  InvokeTransactionParams,
  RequestReturnType,
} from './BaseAdapter'

export class WebAdapter extends BaseAdapter {
  public chain: constants.NetworkName

  public constructor(options: BaseAdapterConstructorOptions) {
    super(options)

    this.chain = options.chain
  }

  public get connected(): boolean {
    return true
  }

  public get accounts(): string[] {
    return ['0x']
  }

  public async init(): Promise<void> {
    return
  }

  public async connect(): Promise<ConnectReturnType> {
    return {
      skipConnection: true,
    }
  }

  public async disconnect(): Promise<DisconnectReturnType> {
    return {
      topic: '',
    }
  }

  public async request(): Promise<RequestReturnType> {
    return {
      error: 'unknown_error',
    }
  }

  public async invokeTransaction(params: InvokeTransactionParams): Promise<RequestReturnType> {
    const { calls } = params.executionRequest

    bot.sendMessage(this.chatId, `Please click the button below to open the web browser and sign the transaction.`, {
      reply_markup: {
        inline_keyboard: [
          [
            {
              text: 'Open Browser',
              url: `https://unruggable.meme/sign-transaction/${encodeURIComponent(JSON.stringify(calls))}`,
            },
          ],
        ],
      },
    })

    return {
      error: 'action_needed',
    }
  }

  public onDisconnect(): void {
    return
  }
}
