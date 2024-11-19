import 'dotenv/config'

import { createMemecoin } from '@unruggable/sdk'
import { logger } from './utils/logger.js'

async function main() {
  logger.info('ici')
}

main().catch((error) => {
  logger.error('An error occurred:', error)
  process.exit(1)
})
