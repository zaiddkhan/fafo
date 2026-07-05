import { useState, type FormEvent } from 'react'
import { addDoc, collection, serverTimestamp } from 'firebase/firestore'
import { db } from '../firebase'

type Status = 'idle' | 'sending' | 'done' | 'error'

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

/**
 * Waitlist email capture. Shared by the hero (blue button) and the final CTA
 * (dark button) so the Firebase submit logic lives in one place.
 */
export function WaitlistForm({
  formClassName = 'notify',
  buttonClassName = 'btn btn-ink btn-lg',
}: {
  formClassName?: string
  buttonClassName?: string
}) {
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

  if (status === 'done') {
    return <div className="thanks">You're on the list. We'll be in touch. 🎉</div>
  }

  return (
    <>
      <form className={formClassName} onSubmit={onSubmit} noValidate>
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
        <button type="submit" className={buttonClassName} disabled={status === 'sending'}>
          {status === 'sending' ? 'Adding…' : 'Notify me'}
        </button>
      </form>
      {status === 'error' && <div className="form-err">{error}</div>}
    </>
  )
}
