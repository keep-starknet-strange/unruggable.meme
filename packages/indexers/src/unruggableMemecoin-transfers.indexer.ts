import { Block, hash } from "./deps.ts";
import { FACTORY_ADDRESS, STARTING_BLOCK } from "./unruggableMemecoin.ts";

export const config = {
  filter: {
    header: { weak: true },
    events: [
      {
        fromAddress: FACTORY_ADDRESS,
        keys: [hash.getSelectorFromName("MemecoinLaunched")],
        includeReceipt: false,
      },
    ],
  },
  streamUrl: "https://mainnet.starknet.a5a.ch",
  startingBlock: STARTING_BLOCK,
  network: "starknet",
  finality: "DATA_STATUS_ACCEPTED",
  sinkType: "postgres",
  sinkOptions: {
    connectionString: "",
    tableName: "unrugmeme_transfers",
  },
};

export function factory({ header, events }) {
  const launchEvents = (events ?? []).map(({ event }) => {
    const memecoin_address = event.data[0];
    return {
      fromAddress: memecoin_address,
      keys: [hash.getSelectorFromName("Transfer")],
      includeReceipt: false,
    };
  });

  return {
    filter: {
      header: { weak: true },
      events: launchEvents,
    },
  };
}


export default function DecodeUnruggableMemecoinLaunch({ header, events }: Block) {
  const { blockNumber, blockHash, timestamp } = header!;

  return (events ?? []).map(({ event, transaction }) => {
    const transactionHash = transaction.meta.hash;
    const transferId = `${transactionHash}_${event.index ?? 0}`;
    const fromAddress = event.keys[1];
    const toAddress = event.keys[2];
    const amount = BigInt(event.data[0]);
    const memecoin_address = event.fromAddress;

    return {
      network: "starknet-mainnet",
      block_hash: blockHash,
      block_number: +blockNumber,
      block_timestamp: timestamp,
      transaction_hash: transactionHash,
      transfer_id: transferId,
      from_address: fromAddress,
      to_address: toAddress,
      memecoin_address: memecoin_address,
      amount: amount.toString(10),
      created_at: new Date().toISOString(),
    };
  });
}
