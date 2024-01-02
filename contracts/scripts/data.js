const NETWORKS = {
    mainnet: {
        name: "mainnet",
        feeder_gateway_url: "https://alpha-mainnet.starknet.io/feeder_gateway",
        gateway_url: "https://alpha-mainnet.starknet.io/gateway",
    },
    goerli: {
        name: "goerli",
        explorer_url: "https://goerli.voyager.online",
        rpc_url: `https://starknet-goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
        feeder_gateway_url: "https://alpha4.starknet.io/feeder_gateway",
        gateway_url: "https://alpha4.starknet.io/gateway",
    },
    sepolia: {
        name: "sepolia",
        explorer_url: "https://sepolia.voyager.online",
        rpc_url: `https://starknet-sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
        feeder_gateway_url: "https://alpha-sepolia.starknet.io/feeder_gateway",
        gateway_url: "https://alpha-sepolia.starknet.io/gateway",
    },
}

const EXCHANGES = {
    mainnet: [
        {
            name: 'JediSwap',
            contract_address: ''
        },
    ],
    goerli: [
        {
            name: 'JediSwap',
            contract_address: '0x02bcc885342ebbcbcd170ae6cafa8a4bed22bb993479f49806e72d96af94c965'
        },
    ],
    sepolia: [
        {
            name: 'JediSwap',
            contract_address: '0x02bcc885342ebbcbcd170ae6cafa8a4bed22bb993479f49806e72d96af94c965'
        },
    ],
}

export const getNetwork = (network) => {
    if (!NETWORKS[network.toLowerCase()]) {
        throw new Error(`Network ${network} not found`);
    }
    return NETWORKS[network];
}

export const getExchanges = (network) => {
    return EXCHANGES[network];
}
