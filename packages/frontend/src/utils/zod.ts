import { PERCENTAGE_INPUT_PRECISION } from 'src/constants/misc'
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
  .refine(
    (input) =>
      +input >= 10 ** -PERCENTAGE_INPUT_PRECISION &&
      new RegExp(`\\d+(\\.\\d{0,${PERCENTAGE_INPUT_PRECISION}})?`).test(input),
    {
      message: 'Invalid percentage',
    }
  )
