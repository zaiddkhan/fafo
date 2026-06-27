import { Phone } from './Phone'
import { MapScreen } from './MapScreen'
import { StoreBadges } from './StoreBadges'

export function Hero() {
  return (
    <section className="hero" id="top">
      <div className="wrap hero-grid">
        <div>
          <span className="eyebrow">Your city, unfiltered</span>
          <h1>
            See what's <span className="hl">popping</span> before the night does.
          </h1>
          <p className="lead">
            FaFo is the live map of what's actually happening around you — right now,
            not last week. Find it, nudge your people, and show up.
          </p>
          <StoreBadges />
          <div className="launch-note">
            <span className="dot" />
            Launching city by city. Get on the list below.
          </div>
        </div>

        <div className="hero-phone-wrap">
          <Phone>
            <MapScreen />
          </Phone>
          <div className="float-card float-streak">
            <span className="fc-emoji">🔥</span>
            <div>
              7-night streak
              <div className="fc-sub">You're out more than 92%</div>
            </div>
          </div>
          <div className="float-card float-nudge">
            <span className="fc-emoji">👋</span>
            <div>
              Maya nudged you
              <div className="fc-sub">"come thru?"</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
