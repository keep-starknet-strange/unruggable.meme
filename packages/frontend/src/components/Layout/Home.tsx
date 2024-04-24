import NavBar from '../NavBar'

export default function HomeLayout({ children }: React.PropsWithChildren) {
  return (
    <>
      <NavBar />
      {children}
    </>
  )
}
