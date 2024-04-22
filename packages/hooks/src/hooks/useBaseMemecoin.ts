import { UseQueryProps } from '../types'
import { useFactory } from './internal/useFactory'
import { useQuery } from './internal/useQuery'

export type UseBaseMemecoinProps = UseQueryProps & {
  address?: string
}

export const useBaseMemecoin = ({ address, ...props }: UseBaseMemecoinProps) => {
  const factory = useFactory()

  return useQuery({
    queryKey: ['baseMemecoin', address],
    queryFn: async () => (address ? factory.getBaseMemecoin(address) : undefined),
    enabled: Boolean(address),
    ...props,
  })
}
