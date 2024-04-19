import { Fraction, Percent } from '@uniswap/sdk-core'

export enum Safety {
  SAFE,
  CORRECT,
  DANGEROUS,
  UNKNOWN,
}

export const TEAM_ALLOCATION_SAFETY_BOUNDS = {
  [Safety.SAFE]: new Percent(1, 100), // 1%
  [Safety.CORRECT]: new Percent(10, 100), // 10%
}

export const STARTING_MCAP_SAFETY_BOUNDS = {
  [Safety.SAFE]: {
    mcap: new Fraction(9000),
    teamAllocatoion: new Fraction(3000),
  },
  [Safety.CORRECT]: {
    mcap: new Fraction(4500),
    teamAllocatoion: new Fraction(5000),
  },
}
