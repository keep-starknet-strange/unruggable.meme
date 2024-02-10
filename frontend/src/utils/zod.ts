import { z } from 'zod'

import { isValidL2Address } from './address'
import { parseFormatedAmount } from './amount'

export const address = z
  .string()
  .refine((address) => isValidL2Address(address), { message: 'Invalid Starknet address' })

export const currencyInput = z
  .string()
  .refine((input) => +parseFormatedAmount(input) > 0, { message: 'Invalid amount' })

export const percentInput = z
  .string()
  .refine((input) => +input <= 100 && +input >= 0.01 && /\d+(\.\d{0,2})?/.test(input), {
    message: 'Invalid percentage',
  })
