import { isMobile } from 'src/utils/userAgent'

// wallet

const getIsArgentXWallet = () => Boolean(window.starknet_argentX)

const getIsBraavosWallet = () => Boolean(window.starknet_braavos)

// advertise

export const getShouldAdvertiseArgentX = () => !getIsArgentXWallet() && !isMobile

export const getShouldAdvertiseBraavos = () => !getIsBraavosWallet()
