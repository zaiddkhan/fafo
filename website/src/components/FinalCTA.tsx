import { useState, type FormEvent } from 'react'
import { addDoc, collection, serverTimestamp } from 'firebase/firestore'
import { db } from '../firebase'
import { StoreBadges } from './StoreBadges'

type Status = 'idle' | 'sending' | 'done' | 'error'

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export function FinalCTA() {
  const [email, setEmail] = useState('')
  const [status, setStatus] = useState<Status>('idle')
  const [error, setError] = useState('')

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    const value = email.trim().toLowerCase()
    if (!EMAIL_RE.test(value)) {
      setError('That email doesn\'t look right — give it another go.')
      setStatus('error')
      return
    }
    setStatus('sending')
    setError('')
    try {
      await addDoc(collection(db, 'waitlist'), {
        email: value,
        source: 'website',
        createdAt: serverTimestamp(),
      })
      setStatus('done')
      setEmail('')
    } catch (err) {
      console.error('waitlist submit failed', err)
      setError('Couldn\'t save that just now. Please try again in a moment.')
      setStatus('error')
    }
  }

  return (
    <section className="cta-band" id="waitlist">
      <div className="wrap">
        <span className="eyebrow">Get on the list</span>
        <h2>Be first when FaFo drops in your city.</h2>
        <p>
          We're rolling out one city at a time. Drop your email and we'll ping you the
          day it goes live where you are.
        </p>

        {status === 'done' ? (
          <div className="thanks">You're on the list. We'll be in touch. 🎉</div>
        ) : (
          <>
            <form className="notify" onSubmit={onSubmit} noValidate>
              <input
                type="email"
                inputMode="email"
                autoComplete="email"
                placeholder="you@email.com"
                aria-label="Email address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
              <button
                type="submit"
                className="btn btn-ink btn-lg"
                disabled={status === 'sending'}
              >
                {status === 'sending' ? 'Adding…' : 'Notify me'}
              </button>
            </form>
            {status === 'error' && <div className="form-err">{error}</div>}
          </>
        )}

        <StoreBadges />
        <p className="cta-sub" style={{ marginTop: 22 }}>
          No spam, ever. One email when we launch near you.
        </p>
      </div>
    </section>
  )
}
