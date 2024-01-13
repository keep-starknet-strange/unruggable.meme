import { z } from 'zod'

import { isValidL2Address } from './address'
import { parseFormatedAmount } from './amount'

export const address = z
  .string()
  .refine((address) => isValidL2Address(address), { message: 'Invalid Starknet address' })

export const currencyInput = z
  .string()
  .refine((input) => +parseFormatedAmount(input) > 0, { message: 'Invalid amount' })

export const percentInput = z.number().multipleOf(0.01)

export const holder = z.object({
  address,
  amount: currencyInput,
})
