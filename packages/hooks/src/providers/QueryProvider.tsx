import { QueryClient, QueryClientProvider, useQueryClient } from '@tanstack/react-query'

const defaultQueryClient = new QueryClient()

type QueryProviderProps = {
  queryClient?: QueryClient
  children?: React.ReactNode
}

export function QueryProvider({ queryClient, children }: QueryProviderProps) {
  const existingQueryClient = useQueryClient()

  // There is already a QueryClientProvider higher up in the tree
  // so we don't need to create a new one
  if (existingQueryClient) {
    return children
  }

  return <QueryClientProvider client={queryClient ?? defaultQueryClient}>{children}</QueryClientProvider>
}
