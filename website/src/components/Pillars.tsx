export function Pillars() {
  return (
    <section className="band" id="features">
      <div className="wrap">
        <div className="sec-head">
          <span className="eyebrow">What you get</span>
          <h2>Three ways FaFo gets you out the door.</h2>
          <p>
            No endless feeds, no FOMO archaeology. Just the map, your people, and a
            reason to actually go.
          </p>
        </div>

        <div className="pillars">
          {/* Map */}
          <div className="pcard">
            <div className="p-emoji">🗺️</div>
            <h3>The live map</h3>
            <p>
              Every event near you on one map, sorted by what's happening now. Tap a pin,
              see the vibe, RSVP in a tap.
            </p>
            <div className="mini">
              <div className="mini-map">
                <div className="pin blue" style={{ top: '24%', left: '22%' }}>🎧</div>
                <div className="pin" style={{ top: '54%', left: '60%' }}>🍻</div>
                <div className="pin" style={{ top: '30%', left: '74%' }}>🍜</div>
              </div>
            </div>
          </div>

          {/* Nudges */}
          <div className="pcard">
            <div className="p-emoji">👋</div>
            <h3>Nudges</h3>
            <p>
              Pull your people out without the group-chat negotiation. Send a nudge, they
              tap yes or no. That's the whole plan.
            </p>
            <div className="mini">
              <div className="nudge-mini">
                <div className="nm-top">
                  <div className="nm-ic">🎧</div>
                  <div>
                    <div className="nm-title">Rooftop Set tonight</div>
                    <div className="nm-meta">From Maya · 9:00 PM</div>
                  </div>
                </div>
                <div className="nm-row">
                  <span className="nm-q">Come thru?</span>
                  <span className="yn">
                    <b className="y">Yes</b>
                    <b className="n">No</b>
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* Quests */}
          <div className="pcard">
            <div className="p-emoji">🏆</div>
            <h3>Quests</h3>
            <p>
              Weekly challenges that reward showing up — try a new spot, bring a friend,
              catch a sunrise. Earn it by being there.
            </p>
            <div className="mini">
              <div className="quest-mini">
                <div className="qm-top">
                  <div className="qm-title">Try a spot you've never been</div>
                  <span className="tag easy">+50</span>
                </div>
                <div className="qm-time">Resets in 2 days</div>
                <div className="qm-row">
                  <span className="qbtn fill">Start</span>
                  <span className="qbtn">Skip</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
