import { UseQueryProps } from '../types'
import { useQuery } from './internal/useQuery'
import { useFactory } from './useFactory'
import { useMemecoin } from './useMemecoin'

export type UseEkuboFeesProps = UseQueryProps & {
  address?: string
}

export const useEkuboFees = ({ address, ...props }: UseEkuboFeesProps) => {
  const factory = useFactory()
  const memecoin = useMemecoin({ address })

  return useQuery({
    queryKey: ['ekuboFees', memecoin.data?.address],
    queryFn: async () => (memecoin.data ? factory.getEkuboFees(memecoin.data) : undefined),
    enabled: Boolean(address),
    ...props,
  })
}
