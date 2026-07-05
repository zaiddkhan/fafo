import { StoreBadges } from './StoreBadges'
import { WaitlistForm } from './WaitlistForm'
import { Wordmark } from './Wordmark'

export function Hero() {
  return (
    <section className="hero" id="top">
      <div className="wrap hero-grid">
        <div>
          <span className="eyebrow">Your city, unfiltered</span>
          <h1>
            Tap in.<br />
            <span className="hl">Nudge up.</span><br />
            Pull up.
          </h1>
          <p className="lead">
            One nudge and your crew's in. <Wordmark /> is the live map of your city right now.
            Spot a plan, send a nudge, they tap yes or no. No negotiation.
          </p>
          <StoreBadges />
          <div className="hero-signup">
            <p className="hero-signup-label">Get on the list and share with your friends.</p>
            <WaitlistForm formClassName="notify" buttonClassName="btn btn-blue" />
          </div>
        </div>

        <div className="hero-media">
          <img
            className="hero-img"
            src="/assets-temp/fafo-hero.png"
            alt="FaFo app — live city map with quest and nudge cards"
          />
          <a href="#waitlist" className="btn btn-blue hero-explore">
            Click here to explore the app
          </a>
        </div>
      </div>
    </section>
  )
}
