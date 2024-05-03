import { AMM, QUOTE_TOKEN_SYMBOL } from 'core/constants'
import * as Icons from 'src/theme/components/Icons'

export const AMM_ICONS: Record<AMM, JSX.Element> = {
  [AMM.EKUBO]: <Icons.Ekubo />,
  [AMM.JEDISWAP]: <Icons.Jediswap />,
  [AMM.STARKDEFI]: <Icons.StarkDeFi />,
}

export const QUOTE_TOKEN_ICONS: Record<QUOTE_TOKEN_SYMBOL, JSX.Element> = {
  [QUOTE_TOKEN_SYMBOL.ETH]: <Icons.ETH />,
  [QUOTE_TOKEN_SYMBOL.STRK]: <Icons.STRK />,
  [QUOTE_TOKEN_SYMBOL.USDC]: <Icons.USDC />,
}
