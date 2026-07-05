const STEPS = [
  { num: 'STEP 01', title: ['Simply Get', 'Onboarded'] },
  { num: 'STEP 02', title: ['Explore', 'Live Events'] },
  { num: 'STEP 03', title: ['Invite', 'Friends'] },
  { num: 'STEP 04', title: ['Complete', 'Quests'] },
]

const STEP_BODY = "See what's going on around you as it happens. Pins, not posts."

export function Steps() {
  return (
    <section className="band" id="how">
      <div className="wrap">
        <div className="sec-head">
          <span className="eyebrow">How it works</span>
          <h2>From <span className="hl">bored to out</span> the door.</h2>
          <p>
            No endless feeds, no FOMO archaeology. Just the map, your people, and a
            reason to actually go.
          </p>
        </div>
        <div className="steps">
          {STEPS.map((s) => (
            <div className="step" key={s.num}>
              <div className="num">{s.num}</div>
              <h4>
                {s.title[0]}
                <br />
                {s.title[1]}
              </h4>
              <p>{STEP_BODY}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
