# Unruggable SDK

A TypeScript SDK for creating and managing Unruggable Memecoins on Starknet. This SDK provides a simple interface for deploying memecoin tokens and launching them on various AMMs.

## Installation

```bash
npm install unruggable-sdk
# or
yarn add unruggable-sdk
```

## Features

- Create new memecoin tokens
- Launch tokens on Ekubo AMM
- Launch tokens on Standard AMM (JediSwap)
- Collect Ekubo fees
- Built-in address validation and amount normalization
- TypeScript support with comprehensive type definitions

## Quick start

```typescript
import { createMemecoin, launchOnEkubo } from 'unruggable-sdk';
import { constants } from "starknet";

// Configure the SDK
const config = {
  starknetProvider: yourProvider,
  starknetChainId: constants.StarknetChainId.SN_MAIN,
};

// Create a new memecoin
const createResult = await createMemecoin(config, {
  name: 'My Memecoin',
  symbol: 'MMC',
  initialSupply: '1000000000',
  owner: ownerAddress,
  starknetAccount: account,
});

// Launch on Ekubo
const launchResult = await launchOnEkubo(config, {
  memecoinAddress: createResult.tokenAddress,
  currencyAddress: ethAddress,
  startingMarketCap: '1000000',
  fees: '3.5',
  holdLimit: '2.5',
  antiBotPeriodInSecs: 300,
  starknetAccount: account,
});
```

## API Reference

### Configuration

The SDK requires a configuration object with the following properties:

```typescript
interface Config {
  starknetProvider: any; // Your Starknet provider
  starknetChainId: string; // Starknet chain ID
}
```

### Functions
#### createMemecoin
Creates a new memecoin token on Starknet.

```typescript
async function createMemecoin(
  config: Config,
  parameters: {
    name: string;
    symbol: string;
    initialSupply: string;
    owner: string;
    starknetAccount: any;
  }
): Promise<{
  transactionHash: string;
  tokenAddress: string;
}>;
```

#### launchOnEkubo
Launches a memecoin on the Ekubo AMM.

```typescript
async function launchOnEkubo(
  config: Config,
  parameters: {
    memecoinAddress: string;
    currencyAddress: string;
    startingMarketCap: string;
    fees: string;
    holdLimit: string;
    antiBotPeriodInSecs: number;
    starknetAccount: any;
  }
): Promise<{
  transactionHash: string;
}>;
```

#### launchOnStandardAMM
Launches a memecoin on JediSwap or StarkDefi

```typescript
async function launchOnStandardAMM(
  config: Config,
  parameters: {
    memecoinAddress: string;
    currencyAddress: string;
    startingMarketCap: string;
    holdLimit: string;
    antiBotPeriodInSecs: number;
    liquidityLockPeriod: number;
    starknetAccount: any;
  }
): Promise<{
  transactionHash: string;
}>;
```

#### collectEkuboFees
Collects accumulated fees from Ekubo pool.

```typescript
async function collectEkuboFees(
  config: Config,
  parameters: {
    memecoinAddress: string;
    starknetAccount: any;
  }
): Promise<{
  transactionHash: string;
} | null>;
```
