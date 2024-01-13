import { createBrowserRouter, RouterProvider } from 'react-router-dom'

import AppLayout from './components/Layout/App'
import HomeLayout from './components/Layout/Home'
import DeployPage from './pages/Deploy'
import HomePage from './pages/Home'
import LaunchPage from './pages/Launch'
import TokenPage from './pages/Token'

const router = createBrowserRouter([
  {
    path: '/',
    element: (
      <HomeLayout>
        <HomePage />
      </HomeLayout>
    ),
  },
  {
    path: '/deploy',
    element: (
      <AppLayout>
        <DeployPage />
      </AppLayout>
    ),
  },
  {
    path: '/launch',
    element: (
      <AppLayout>
        <LaunchPage />
      </AppLayout>
    ),
  },
  {
    path: '/token/:address',
    element: (
      <AppLayout>
        <TokenPage />
      </AppLayout>
    ),
  },
])

export default function App() {
  return <RouterProvider router={router} />
}
