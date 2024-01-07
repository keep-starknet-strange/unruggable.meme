# Unruggable Memecoin contracts

## TODO

- [ ] `launch_memecoin` function
  - [ ] Create pair on selected Exchange
  - [ ] Add liquidity to pair
  - [ ] Enable trading
- [ ] Initial holders distribution safeguards
  - [ ] Limit initial holders to X addresses (with X small)
  - [ ] Limit the percentage of the total supply that can be distributed to initial holders
- [ ] Inital buys safeguards
  - [ ] Limit the percentage of the total supply that can be bought in the first X blocks

## 🛠️ Build

To build the project, run:

```bash
scarb build
```

## 🧪 Test

To test the project, run:

```bash
snforge
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
