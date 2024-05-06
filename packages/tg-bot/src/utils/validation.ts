import { z, ZodSchema } from 'zod'

import { bot } from '../services/bot'
import { isValidStarknetAddress } from './helpers'

const int = <TSchema extends ZodSchema>(schema: TSchema) => z.preprocess((x) => String(x).replace(/[.,]/g, ''), schema)

const number = z.coerce.number({
  invalid_type_error: 'Please provide a valid number.',
  required_error: 'Please provide a valid number.',
})

export const validateAndSend = <T, TSchema extends ZodSchema>(
  chatId: number,
  value: T,
  schema: TSchema,
): TSchema['_output'] | false => {
  const parsed = schema.safeParse(value)
  if (parsed.success) return parsed.data

  const error = parsed.error.flatten().formErrors[0]
  if (error) {
    bot.sendMessage(chatId, error, { parse_mode: 'Markdown' })
  }

  return false
}

export const addressValidation = z
  .string({
    invalid_type_error: 'Please provide a valid *Address*.',
    required_error: 'Please provide a valid *Address*.',
  })
  .refine((value) => isValidStarknetAddress(value), 'Please provide a valid Starknet address.')

export const DeployValidation = {
  name: z
    .string({
      invalid_type_error: 'Please provide a valid *Name*.',
      required_error: "*Name* can't be shorter than 2 characters.",
    })
    .min(2, "*Name* can't be shorter than 2 characters.")
    .max(256, "*Name* can't be longer than 256 characters"),

  symbol: z
    .string({
      invalid_type_error: 'Please provide a valid *Symbol*.',
      required_error: "*Symbol* can't be shorter than 2 characters.",
    })
    .min(2, "*Symbol* can't be shorter than 2 characters.")
    .max(256, "*Symbol* can't be longer than 256 characters"),

  ownerAddress: addressValidation,

  initialSupply: int(number.min(1, '*Initial supply* must be greater than 0')),
}

export const LaunchValidation = {
  address: addressValidation,

  teamAllocationAmount: int(number.min(1, '*Initial supply* must be greater than 0')),
  teamAllocationAddress: addressValidation,

  holdLimit: number.min(0.5, '*Hold limit* cannot fall behind 0.5%').max(100, '*Hold limit* cannot exceed 100%'),

  antiBotPeriod: z
    .string()
    .regex(/^(24:00)|(([01]\d|2[0-3]):([0-5]\d))$/, 'Please provide a time in HH:MM format. Example: 24:00'),

  startingMarketCap: int(number.min(5000, '*Market Cap* cannot fall behind 5.000$')),

  ekuboFees: number.min(0.01, '*Ekubo Fees* cannot fall behind 0.01%').max(2, '*Ekubo Fees* cannot exceed 2%'),

  lockLiquidty: z.union([
    z
      .string()
      .refine(
        (value) => value.toLowerCase() === 'forever',
        'Please provide a valid number between 6 and 24, or type *forever* for permanent lock',
      ),
    number
      .int()
      .min(6, "*Liquidity Lock* can't be shorter than 6 months")
      .max(24, "*Liquidity Lock* can't be longer than 24 months"),
  ]),
}
