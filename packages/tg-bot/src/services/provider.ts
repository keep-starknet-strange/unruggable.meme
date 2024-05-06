import { RpcProvider } from 'starknet'

// replace the value below with the Telegram token you receive from @BotFather
const nodeUrl = process.env.NODE_URL

// Exit if the node url is not provided
if (!nodeUrl) {
  console.error('NODE_URL is not provided')
  process.exit(1)
}

export const provider = new RpcProvider({ nodeUrl })
