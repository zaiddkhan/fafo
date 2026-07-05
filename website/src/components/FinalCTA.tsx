import { WaitlistForm } from './WaitlistForm'

export function FinalCTA() {
  return (
    <section className="cta-band" id="waitlist">
      <div className="wrap">
        <span className="eyebrow">Get on the list</span>
        <h2>Be first when FaFo drops in your city.</h2>
        <p>
          We're rolling out one city at a time. Drop your email and we'll ping you the
          day it goes live where you are.
        </p>

        <WaitlistForm />

        <p className="cta-sub">
          No spam, ever. One email when we launch near you.
        </p>
      </div>
    </section>
  )
}
