import { createBrowserRouter, RouterProvider } from 'react-router-dom'

import NavBar from './components/NavBar'
import HomePage from './pages/Home'
import LaunchPage from './pages/Launch'
import ManagePage from './pages/Manage'

interface LayoutWrapperProps {
  children: React.ReactNode
}

function LayoutWrapper({ children }: LayoutWrapperProps) {
  return (
    <>
      <NavBar />
      {children}
    </>
  )
}

const router = createBrowserRouter([
  {
    path: '/',
    element: (
      <LayoutWrapper>
        <HomePage />
      </LayoutWrapper>
    ),
  },
  {
    path: '/launch',
    element: (
      <LayoutWrapper>
        <LaunchPage />
      </LayoutWrapper>
    ),
  },
  {
    path: '/manage',
    element: (
      <LayoutWrapper>
        <ManagePage />
      </LayoutWrapper>
    ),
  },
])

export default function App() {
  return <RouterProvider router={router} />
}
