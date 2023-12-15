import { z } from 'zod'

// https://starkscan.readme.io/reference/contract-object
const contractSchema = z.object({
  deployed_at_timestamp: z.number(),
  contract: z.string(),
  status: z.string(),
  type: z.string(),
})

export type Contract = z.infer<typeof contractSchema>
