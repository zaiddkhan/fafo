import { Phone } from './Phone'
import { CheckIcon, QrIcon, UsersIcon, PlusIcon } from './icons'

function FriendsScreen() {
  return (
    <div className="scr-pad">
      <div className="scr-h">
        <div className="t">Friends</div>
        <span className="pill-ink">+ Add</span>
      </div>
      <div className="seg">
        <b className="on">Friends</b>
        <b>Requests</b>
        <b>Find</b>
      </div>
      <div className="twobtn">
        <div className="tb">
          <UsersIcon />
          Sync contacts
        </div>
        <div className="tb">
          <QrIcon />
          Invite
        </div>
      </div>

      <div className="fr-card">
        <div className="av">MR</div>
        <div>
          <div className="fn">Maya R.</div>
          <div className="fs">Out tonight · Rooftop Set</div>
        </div>
        <div className="dots">···</div>
      </div>
      <div className="fr-card">
        <div className="av">DK</div>
        <div>
          <div className="fn">Dev K.</div>
          <div className="fs">7-night streak 🔥</div>
        </div>
        <div className="dots">···</div>
      </div>
      <div className="fr-card">
        <div className="av">SO</div>
        <div>
          <div className="fn">Sana O.</div>
          <div className="fs">In your area now</div>
        </div>
        <div className="dots">···</div>
      </div>
    </div>
  )
}

function QuestsScreen() {
  return (
    <div className="scr-pad">
      <div className="scr-h">
        <div className="t">Quests</div>
        <span className="pill-ink">🔥 7</span>
      </div>
      <div className="sub-l">Resets Sunday · 2 of 4 cleared</div>

      <div className="norm-row">
        <span className="nl">This week</span>
        <span className="vr">+150 pts</span>
      </div>

      <div className="q-card">
        <div className="qc-top">
          <div className="qc-title">Catch a set you've never heard</div>
          <span className="tag hard">+80</span>
        </div>
        <div className="qc-time">Ends in 2 days</div>
        <div className="qc-line">
          Tip: <u>Rooftop Set</u> tonight counts.
        </div>
        <div className="qc-row">
          <span className="qbtn fill">Find one</span>
          <span className="qbtn">Skip</span>
        </div>
      </div>

      <div className="q-card">
        <div className="qc-top">
          <div className="qc-title">Bring a friend out</div>
          <span className="tag easy">+50</span>
        </div>
        <div className="done">
          <CheckIcon style={{ width: 16, height: 16 }} />
          Done — nice one
        </div>
      </div>

      <div className="q-card">
        <div className="qc-top">
          <div className="qc-title">Try a new neighborhood</div>
          <span className="tag easy">+20</span>
        </div>
        <div className="qc-time">Ends in 2 days</div>
        <div className="qc-row">
          <span className="qbtn fill">
            <PlusIcon style={{ width: 13, height: 13, verticalAlign: '-2px' }} /> Start
          </span>
          <span className="qbtn">Skip</span>
        </div>
      </div>
    </div>
  )
}

export function Showcase() {
  return (
    <section className="band" id="peek">
      <div className="wrap">
        <div className="sec-head" style={{ marginInline: 'auto', textAlign: 'center' }}>
          <span className="eyebrow">A peek inside</span>
          <h2>Built for the people you actually go out with.</h2>
        </div>

        <div className="showcase">
          <div className="show-col">
            <Phone>
              <FriendsScreen />
            </Phone>
            <div className="cap">
              Your circle <span>— see who's out, sync contacts, send invites</span>
            </div>
          </div>

          <div className="show-col">
            <Phone>
              <QuestsScreen />
            </Phone>
            <div className="cap">
              Weekly quests <span>— rewards for showing up, not scrolling</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
