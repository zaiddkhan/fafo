import { Header } from './components/Header'
import { Hero } from './components/Hero'
import { Pillars } from './components/Pillars'
import { Steps } from './components/Steps'
import { Showcase } from './components/Showcase'
import { FinalCTA } from './components/FinalCTA'
import { Footer } from './components/Footer'

export default function App() {
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
