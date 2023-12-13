import { createBrowserRouter, RouterProvider } from 'react-router-dom'

import AppLayout from './components/Layout/App'
import HomeLayout from './components/Layout/Home'
import HomePage from './pages/Home'
import LaunchPage from './pages/Launch'
import ManagePage from './pages/Manage'

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
])

export default function App() {
  return <RouterProvider router={router} />
}
