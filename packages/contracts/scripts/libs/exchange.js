const EXCHANGES = {
  mainnet: [
    {
      name: 'JediSwap',
      contract_address: '0x041fd22b238fa21cfcf5dd45a8548974d8263b3a531a60388411c5e230f97023',
    },
    {
      "name": "Ekubo",
      "contract_address": "0x00000005dd3D2F4429AF886cD1a3b08289DBcEa99A294197E9eB43b0e0325b4b"
    }
  ],
  sepolia: [
    {
      name: 'JediSwap',
      contract_address: '0x0',
    },
    {
      name: "Ekubo",
      contract_address: '0x0444a09d96389aa7148f1aada508e30b71299ffe650d9c97fdaae38cb9a23384'
    }
  ],
}

export const getExchanges = (network) => {
  if (!EXCHANGES[network.toLowerCase()]) {
    throw new Error(`Network ${network} not found`)
  }
  return EXCHANGES[network.toLowerCase()]
}
