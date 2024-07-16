import { drizzle } from 'drizzle-orm/node-postgres'
import { bigint, pgTable, text, timestamp } from 'drizzle-orm/pg-core'
import { Pool } from 'pg'

if (!process.env.INDEXER_DB_CONNECTION_STRING) {
  throw new Error('INDEXER_DB_CONNECTION_STRING environment variable is not set')
}

const pool = new Pool({
  connectionString: process.env.INDEXER_DB_CONNECTION_STRING,
})

export const db = drizzle(pool)

const commonSchema = {
  cursor: bigint('_cursor', { mode: 'number' }),
  createdAt: timestamp('created_at', { mode: 'date', withTimezone: false }),

  network: text('network'),
  blockHash: text('block_hash'),
  blockNumber: bigint('block_number', { mode: 'number' }),
  blockTimestamp: timestamp('block_timestamp', { mode: 'date', withTimezone: false }),
  transactionHash: text('transaction_hash'),
}

export const deploy = pgTable('unrugmeme_deploy', {
  ...commonSchema,

  token: text('memecoin_address').primaryKey(),
  owner: text('owner_address'),
  name: text('name'),
  symbol: text('symbol'),
  initialSupply: text('initial_supply'),
})

export const launch = pgTable('unrugmeme_launch', {
  ...commonSchema,

  token: text('memecoin_address').primaryKey(),
  quoteToken: text('quote_token'),
  exchangeName: text('exchange_name'),
})

export const transfer = pgTable('unrugmeme_transfers', {
  ...commonSchema,

  transferId: text('transfer_id').primaryKey(),
  from: text('from_address'),
  to: text('to_address'),
  token: text('memecoin_address'),
  amount: text('amount'),
})
