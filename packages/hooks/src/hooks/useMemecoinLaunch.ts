import { UseQueryProps } from '../types'
import { useFactory } from './internal/useFactory'
import { useQuery } from './internal/useQuery'

export type UseMemecoinLaunchProps = UseQueryProps & {
  address?: string
}

export const useMemecoinLaunch = ({ address, ...props }: UseMemecoinLaunchProps) => {
  const factory = useFactory()

  return useQuery({
    queryKey: ['memecoinLaunchData', address],
    queryFn: async () => (address ? factory.getMemecoinLaunchData(address) : undefined),
    enabled: Boolean(address),
    ...props,
  })
}
