import { Wordmark } from './Wordmark'

export function Pillars() {
  return (
    <section className="band" id="features">
      <div className="wrap">
        <div className="sec-head">
          <span className="eyebrow">What you get</span>
          <h2>Three ways <span className="hl"><Wordmark /> helps you</span> go out</h2>
        </div>

        <div className="pillars">
          {/* Live Map */}
          <div className="pcard">
            <h3>Live Map</h3>
            <p className="p-sub">The whole city on one map, live.</p>
            <ul className="p-bullets">
              <li>Tap a pin to see what's going on</li>
              <li>Browse from your favourite categories</li>
              <li>Explore spotlight to see today's special events</li>
              <li>Join the event with single click &amp; get reminded</li>
            </ul>
            <img className="p-shot" src="/assets-temp/live-map-card.png" alt="Live map of the city" />
          </div>

          {/* Nudges */}
          <div className="pcard">
            <h3>Nudges</h3>
            <p className="p-sub">For quick &amp; repetitive plans.</p>
            <ul className="p-bullets">
              <li>Turn daily group rituals into quick nudges</li>
              <li>Send in your friend group without typing every time</li>
              <li>Just accept or deny, no need to make excuses.</li>
              <li>Simple reminders for your &ldquo;busy&rdquo; friends</li>
            </ul>
            <img className="p-shot" src="/assets-temp/nudges-card.png" alt="Nudge to meet at a coffee place" />
          </div>

          {/* Quests */}
          <div className="pcard">
            <h3>Quests</h3>
            <p className="p-sub">For quick &amp; repetitive plans.</p>
            <ul className="p-bullets">
              <li>Turn daily group rituals into quick nudges</li>
              <li>Send in your friend group without typing every time</li>
              <li>Just accept or deny, no need to make excuses.</li>
              <li>Simple reminders for your &ldquo;busy&rdquo; friends</li>
            </ul>
            <img className="p-shot" src="/assets-temp/quests-card.png" alt="Quest to try a new restaurant" />
          </div>
        </div>
      </div>
    </section>
  )
}
