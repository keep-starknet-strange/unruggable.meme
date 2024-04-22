# Unruggable Memecoin contracts

This repository contains the contracts used in the Unruggable Memecoin framework.

## Features

The Unruggable framework enables the creation of a memecoin in two steps.

1. The first step is to deploy the Memecoin contract using the Factory contract, specifying the owner of the memecoin, its name, symbol, and the total supply. The memecoin is compliant with the ERC20 standard, plus a few extra functions to enable the framework to interact with it, such as:

   - `is_launched`: Returns whether the memecoin is launched already.
   - `get_team_allocation`: Returns the amount of tokens allocated to the team.
   - `liquidity_type`: Returns the type of liquidity the memecoin is using - either an NFT on Ekubo, or a ERC20 pair on an UniV2-like AMM.
   -

2. The second step is to launch the memecoin on the desired exchange. The framework currently supports both Jediswap and Ekubo, and the process is fully automated.
   When launching a token, the creator of a memecoin must provide the following parameters:

   - The address of the memecoin to launch.
   - The duration of transfer restrictions, which disable buying more than a certain percentage of the total supply in a single transaction.
   - The maximum percentage of the total supply that can be bought in a single transaction while the restriction is active.
   - The address of the quote token to use in the liquidity pool.

Depending on which exchange the liquidity is supplied, the process is different:

- **Jediswap**: Launching on Jediswap requires providing an amount of liquidity in quote tokens (for example, ETH or STRK) to the pool and the unlock time for the LP tokens. The amount of liquidity provided at launch will determine the initial price (and marketcap) of the token, and the liquidity position minted is transferred to a locker for a minimal duration of 6 months, which can be parametrized at launch.

- **Ekubo**: Launching on Ekubo enables us to provide liquidity only between fixed bounds - and thus enables us to launch a memecoin without depositing a large amount of quote tokens. As such, **launching on Ekubo is a lot more capital efficient**. In theory, one could even launch a memecoin without any initial liquidity - but this would impose a risk if the team had allocated itself initial coins and sold them in the pool, as it could dry up the total liquidity. Therefore, launching on Ekubo works as follows:

  1.  The team must provide some liquidity in quote token, corresponding to the number of tokens they allocated to themselves at the starting price of the token. They send this liquidity to the factory.
  2.  The factory creates the liquidity positions in two steps: First, it supplies the amount of the team's allocation between the bounds $[starting\_price + tick\_spacing, +\infty]$. Then, it supplies the remaining liquidity between the bounds $[starting\_price + tick\_spacing, +\infty]$.
  3.  Then, the factory uses the amount in quote token provided by the team to buyback their tokens from the pool. Since the team allocation has been entirely concentrated in the first tick, the effective price at which the tokens will be bought back is the starting price (+/- the fees and effective price inside the tick). The tokens bought back are then transferred to the initial holders specified at launch.
  4.  The principal liquidity position minted is kept in the EkuboLauncher contract, which manages all interactions with Ekubo. As such, the Ekubo liquidity will be **locked forever**, and the fees earned from the pool will be withdrawable by the owners of the memecoin by interacting with the EkuboLauncher contract.

## Structure

### Contracts

- [**Factory**](contracts/src/factory/factory.cairo): The factory contract responsible for creating and launching Memecoin. This is the entrypoint to any interaction with components of the framework.
- [**Memecoin**](contracts/src/token/memecoin.cairo): The Memecoin contract that represents the token itself. It is deployed by the factory and contains all the properties of the ERC20 token standard, plus a few extra functions to enable the framework to interact with it.
- [**Locker manager**](contracts/src/locker/locker_manager.cairo): This contract manages the lock functionality of tokens. It can be used with any ERC20 tokens - even tokens with increasing balanceOf - to lock tokens for a certain period of time. Each lock deploys a specific contract that holds the locked tokens and can be released after the lock period, as it abstracts the accountability of token balances. All interactions must be made through the LockerManager contract.
- [**EkuboLauncher**](contracts/exchanges/ekubo/launcher.cairo): The contract that launches the Memecoin on the Ekubo exchange. As launching a memecoin requires a few steps, this contract is responsible for automating the process. It creates the pool on Ekubo, adds liquidity to the pair, and holds the liquidity position minted. Owners of memecoins can withdraw the fees earned from the liquidity pool by interacting with this contract.

### Tests

The [tests](contracts/src/tests) directory contains the tests for the framework. The tests are written using [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/index.html), a testing framework for Cairo and Starknet contracts. It is organized as follows:

- [_fork_tests_](contracts/src/tests/fork_tests): Tests that run on a fork of Starknet mainnet. These tests are used to test the contracts in a real environment. It is mostly used to test the interactions with Ekubo.
- [_unit_tests_](contracts/src/tests/unit_tests): Tests that run locally to test the contracts in isolation. It tests all the contracts and their interactions. It also tests the global interactions with Jediswap, as we can deploy them locally.

## 🛠️ Build

To build the project, run:

```bash
scarb build
```

## 🧪 Test

To test the project, you will need an API key from an RPC provider. We recommend using either the Nethermind RPC or BlastAPI, as they support v6.0 RPC. Once you have an API key, you can edit the `[[tool.snforge.fork]]` section of the `Scarb.toml` file to include the URL of your RPC provider.

Then, you can run the tests using:

```bash
snforge test
```

If you only want to run unit tests, you don't need an RPC provider. You can run the tests using:

```bash
snforge test unit_tests
```

## 🚀 Deploy

To deploy the project on testnet, you need to:

- Change directory to `scripts` folder
- Copy and update the `.env.example` file into `scripts/.env`
- Run the deployment script using `npm run deploy`

## 📚 Resources

Here are some resources to help you get started:

- [Cairo Book](https://book.cairo-lang.org/)
- [Starknet Book](https://book.starknet.io/)
- [Starknet Foundry Book](https://foundry-rs.github.io/starknet-foundry/)
- [Starknet By Example](https://starknet-by-example.voyager.online/)
- [Starkli Book](https://book.starkli.rs/)

## 📖 License

This project is licensed under the **MIT license**. See [LICENSE](LICENSE) for more information.
