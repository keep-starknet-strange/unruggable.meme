/// <reference types="react-scripts" />

interface Window {
  // walletLinkExtension is injected by the Coinbase Wallet extension
  walletLinkExtension?: any
  ethereum?: {
    // set by the Coinbase Wallet mobile dapp browser
    isCoinbaseWallet?: true
    // set by the Brave browser when using built-in wallet
    isBraveWallet?: true
    // set by the MetaMask browser extension (also set by Brave browser when using built-in wallet)
    isMetaMask?: true
    // set by the Rabby browser extension
    isRabby?: true
    // set by the Trust Wallet browser extension
    isTrustWallet?: true
    // set by the Ledger Extension Web 3 browser extension
    isLedgerConnect?: true
    autoRefreshOnNetworkChange?: boolean
  }
  web3?: Record<string, unknown>
  starknet_argentX?: any
  starknet_braavos?: any
}
