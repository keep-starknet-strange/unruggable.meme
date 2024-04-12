import { useMemo } from 'react'

const useStarkscanUrl = (address?: string) =>
  useMemo(() => (address ? `https://starkscan.co/token/${address}` : undefined), [address])

const useVoyagerUrl = (address?: string) =>
  useMemo(() => (address ? `https://voyager.online/token/${address}` : undefined), [address])

const useDexscreenerUrl = (address?: string) =>
  useMemo(() => (address ? `https://dexscreener.com/starknet/${address}` : undefined), [address])

export default function useLinks(address?: string) {
  return {
    voyager: useVoyagerUrl(address),
    starkscan: useStarkscanUrl(address),
    dexscreener: useDexscreenerUrl(address),
  }
}
