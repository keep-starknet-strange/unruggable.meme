import { Block, hash } from "./deps.ts";
import { decodeShortString } from "https://esm.sh/gh/starknet-io/starknet.js@66a5c0341e/src/utils/shortString.ts";
import { FACTORY_ADDRESS, STARTING_BLOCK } from "./unruggableMemecoin.ts";

const filter = {
  header: {
    weak: true,
  },
  events: [
    {
      fromAddress: FACTORY_ADDRESS,
      keys: [hash.getSelectorFromName("MemecoinLaunched") as FieldElement],
      includeReceipt: false,
    },
  ],
};

export const config = {
  streamUrl: "https://mainnet.starknet.a5a.ch",
  startingBlock: STARTING_BLOCK,        
  network: "starknet",
  finality: "DATA_STATUS_ACCEPTED",
  filter,
  sinkType: "postgres",
  sinkOptions: {
    connectionString: "",
    tableName: "unrugmeme_transfers",
  },
};


export default function DecodeUnruggableMemecoinLaunch({ header, events }: Block) {
  const { blockNumber, blockHash, timestamp } = header!;
  
  return (events ?? []).map(({ event, transaction }) => {
    const transactionHash = transaction.meta.hash;
    const eventId = `${transactionHash}_${event.index ?? 0}`;

    const [memecoin_address, quote_token, exchange_name] =
      event.data;
    
    const exchange_name_decoded = decodeShortString(exchange_name);

    return {
      network: "starknet-mainnet",
      block_hash: blockHash,
      block_number: +blockNumber,
      block_timestamp: timestamp,
      transaction_hash: transactionHash,
      event_id: eventId,
      memecoin_address: memecoin_address,
      quote_token: quote_token,
      exchange_name: exchange_name_decoded.replace(/\u0000/g, ''),
      created_at: new Date().toISOString(),
    };
  });
}
