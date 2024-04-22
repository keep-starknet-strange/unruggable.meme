import { UseQueryProps } from '../types'
import { useQuery } from './internal/useQuery'
import { useFactory } from './useFactory'

export type UseMemecoinProps = UseQueryProps & {
  address?: string
}

export const useMemecoin = ({ address, ...props }: UseMemecoinProps) => {
  const factory = useFactory()

  return useQuery({
    queryKey: ['memecoin', address],
    queryFn: async () => (address ? factory.getMemecoin(address) : undefined),
    enabled: Boolean(address),
    ...props,
  })
}
