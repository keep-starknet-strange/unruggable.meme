import { QueryClient, QueryClientProvider, useQueryClient } from '@tanstack/react-query'

const defaultQueryClient = new QueryClient()

interface QueryProviderProps {
  queryClient?: QueryClient
}

export function QueryProvider({ queryClient, children }: React.PropsWithChildren<QueryProviderProps>) {
  const existingQueryClient = useQueryClient()

  // There is already a QueryClientProvider higher up in the tree
  // so we don't need to create a new one
  if (existingQueryClient) {
    return children
  }

  return <QueryClientProvider client={queryClient ?? defaultQueryClient}>{children}</QueryClientProvider>
}
