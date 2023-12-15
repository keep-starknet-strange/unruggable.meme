import { createBrowserRouter, RouterProvider } from 'react-router-dom'

import AppLayout from './components/Layout/App'
import HomeLayout from './components/Layout/Home'
import HistoryPage from './pages/History'
import HomePage from './pages/Home'
import LaunchPage from './pages/Launch'
import ManagePage from './pages/Manage'
import ScreenPage from './pages/Screen'

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
    path: '/launch',
    element: (
      <AppLayout>
        <LaunchPage />
      </AppLayout>
    ),
  },
  {
    path: '/manage',
    element: (
      <AppLayout>
        <ManagePage />
      </AppLayout>
    ),
  },
  {
    path: '/screen',
    element: (
      <AppLayout>
        <ScreenPage />
      </AppLayout>
    ),
  },
  {
    path: '/history',
    element: (
      <AppLayout>
        <HistoryPage />
      </AppLayout>
    ),
  },
])

export default function App() {
  return <RouterProvider router={router} />
}
