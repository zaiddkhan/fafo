import { useState } from 'react'
import { Logo } from './icons'

export function Header() {
  const [open, setOpen] = useState(false)
  const close = () => setOpen(false)

  return (
    <header>
      <div className="wrap nav">
        <a href="#top" className="brand" onClick={close}>
          <Logo />
          FaFo
        </a>

        <nav className={`nav-links${open ? ' open' : ''}`}>
          <a href="#how" onClick={close}>How it works</a>
          <a href="#features" onClick={close}>Features</a>
          <a href="#peek" onClick={close}>The app</a>
          <a href="#waitlist" onClick={close}>Join the waitlist</a>
        </nav>

        <div className="nav-cta">
          <a href="#waitlist" className="btn btn-blue">Get early access</a>
          <button
            className="menu-btn"
            aria-label="Toggle menu"
            aria-expanded={open}
            onClick={() => setOpen((v) => !v)}
          >
            <span />
          </button>
        </div>
      </div>
    </header>
  )
}
