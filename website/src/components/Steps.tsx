const STEPS = [
  { num: 'STEP 01', emoji: '📍', title: 'Open the map', body: 'See what\'s happening around you in real time — pins, not posts.' },
  { num: 'STEP 02', emoji: '👀', title: 'Find your night', body: 'Filter by tonight, free, music, food. Tap a pin, check the vibe.' },
  { num: 'STEP 03', emoji: '👋', title: 'Nudge your crew', body: 'One tap pulls your people in. They say yes, you\'ve got a plan.' },
  { num: 'STEP 04', emoji: '🏆', title: 'Show up, earn it', body: 'Check in, keep your streak, clear quests, climb your circle.' },
]

export function Steps() {
  return (
    <section className="band cream" id="how">
      <div className="wrap">
        <div className="sec-head">
          <span className="eyebrow">How it works</span>
          <h2>From bored to out the door in four taps.</h2>
        </div>
        <div className="steps">
          {STEPS.map((s) => (
            <div className="step" key={s.num}>
              <div className="num">{s.num}</div>
              <span className="s-emoji">{s.emoji}</span>
              <h4>{s.title}</h4>
              <p>{s.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
