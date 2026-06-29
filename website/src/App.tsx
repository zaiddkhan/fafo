import { lazy, Suspense } from 'react'
import { Route, Routes } from 'react-router-dom'
import { Header } from './components/Header'
import { Hero } from './components/Hero'
import { Pillars } from './components/Pillars'
import { Steps } from './components/Steps'
import { Showcase } from './components/Showcase'
import { FinalCTA } from './components/FinalCTA'
import { Footer } from './components/Footer'

// The admin panel is a separate concern from the marketing site; lazy-load it so
// it never ships in the landing-page bundle.
const AdminApp = lazy(() => import('./admin/AdminApp'))

function Landing() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Pillars />
        <Steps />
        <Showcase />
        <FinalCTA />
      </main>
      <Footer />
    </>
  )
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Landing />} />
      <Route
        path="/admin/*"
        element={
          <Suspense fallback={null}>
            <AdminApp />
          </Suspense>
        }
      />
    </Routes>
  )
}
