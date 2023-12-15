import NavBar from '../NavBar'

interface HomeLayoutProps {
  children: React.ReactNode
}

export default function HomeLayout({ children }: HomeLayoutProps) {
  return (
    <>
      <NavBar />
      {children}
    </>
  )
}
