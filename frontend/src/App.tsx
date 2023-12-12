import { createBrowserRouter, RouterProvider } from 'react-router-dom'

import NavBar from './components/NavBar'
import HomePage from './pages/Home'

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
])

export default function App() {
  return <RouterProvider router={router} />
}
