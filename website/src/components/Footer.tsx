import { Logo } from './icons'

export function Footer() {
  const year = 2026
  return (
    <footer>
      <div className="wrap">
        <div className="foot-grid">
          <div className="foot-brand">
            <a href="#top" className="brand">
              <Logo />
              FaFo
            </a>
            <p>The live map of what's actually happening around you. Your city, unfiltered.</p>
          </div>

          <div className="foot-col">
            <h5>Product</h5>
            <a href="#features">Features</a>
            <a href="#how">How it works</a>
            <a href="#peek">The app</a>
            <a href="#waitlist">Waitlist</a>
          </div>

          <div className="foot-col">
            <h5>Company</h5>
            <a href="#top">About</a>
            <a href="mailto:hello@getfafo.app">Contact</a>
            <a href="#waitlist">Careers</a>
          </div>

          <div className="foot-col">
            <h5>Legal</h5>
            <a href="/privacy">Privacy</a>
            <a href="/terms">Terms</a>
          </div>
        </div>

        <div className="foot-bottom">
          <p>© {year} FaFo. All rights reserved.</p>
          <div className="fb-links">
            <a href="https://instagram.com" target="_blank" rel="noreferrer">Instagram</a>
            <a href="https://www.tiktok.com" target="_blank" rel="noreferrer">TikTok</a>
            <a href="https://x.com" target="_blank" rel="noreferrer">X</a>
          </div>
        </div>
      </div>
    </footer>
  )
}
