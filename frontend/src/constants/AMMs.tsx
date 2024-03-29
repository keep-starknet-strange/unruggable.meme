import * as Icons from 'src/theme/components/Icons'

import { Selector } from './misc'

export enum AMM {
  EKUBO = 'Ekubo',
  JEDISWAP = 'Jediswap',
  STARKDEFI = 'StarkDeFi',
}

export const AmmInfos = {
  [AMM.EKUBO]: {
    description:
      'Most efficient AMM ever, you can launch your token without having to provide liquidity and can collect fees.',
    icon: <Icons.Ekubo />,
  },
  [AMM.JEDISWAP]: {
    description:
      "Widely supported AMM, team allocation will be free but you have to provide liquidity and can't collect fees.",
    icon: <Icons.Jediswap />,
    launchEntrypoint: Selector.LAUNCH_ON_JEDISWAP,
  },
  [AMM.STARKDEFI]: {
    description: "Team allocation will be free but you have to provide liquidity and can't collect fees.",
    icon: <Icons.StarkDeFi />,
    launchEntrypoint: Selector.LAUNCH_ON_STARKDEFI,
  },
}
