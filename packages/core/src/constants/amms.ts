import { Entrypoint } from './misc'

export enum AMM {
  EKUBO = 'Ekubo',
  JEDISWAP = 'Jediswap',
  STARKDEFI = 'StarkDeFi',
}

export const AMMS = {
  [AMM.EKUBO]: {
    description:
      'Most efficient AMM ever, you can launch your token without having to provide liquidity and can collect fees.',
    launchEntrypoint: Entrypoint.LAUNCH_ON_EKUBO,
  },
  [AMM.JEDISWAP]: {
    description:
      "Widely supported AMM, team allocation will be free but you have to provide liquidity and can't collect fees.",
    launchEntrypoint: Entrypoint.LAUNCH_ON_JEDISWAP,
  },
  [AMM.STARKDEFI]: {
    description: "Team allocation will be free but you have to provide liquidity and can't collect fees.",
    launchEntrypoint: Entrypoint.LAUNCH_ON_STARKDEFI,
  },
}
