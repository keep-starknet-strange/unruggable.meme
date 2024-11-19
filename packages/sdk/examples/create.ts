import { createMemecoin, Config } from '../src'
import { RpcProvider, Account } from "starknet";

const starknetProvider = new RpcProvider({ nodeUrl: "https://starknet-mainnet.public.blastapi.io" });

const config: Config = {
    starknetProvider
}

const starknetAccount = new Account(
    starknetProvider,
    "0x0416Ba0f3d21Eda5A87d05d0aCC827075792132697E9eD973F4390808790a11A",
    "0x05c15e38bc5ff56529a9e9bcca4a62daa601285a419884c29493ac145b8a3fad"
  );

createMemecoin(config, {
    initialSupply: "1000000",
    name: "test",
    owner: "TST123",
    starknetAccount,
    symbol: "TEST123"
})