import { AppleIcon, PlayIcon } from './icons'

/** App Store / Play Store badges. Both marked "Soon" until the apps ship. */
export function StoreBadges() {
  return (
    <div className="badges">
      <div className="badge ios" role="button" aria-label="Coming soon to the App Store">
        <AppleIcon />
        <div>
          <div className="b-top">Download on the</div>
          <div className="b-main">App Store</div>
        </div>
        <span className="soon">Soon</span>
      </div>
      <div className="badge" role="button" aria-label="Coming soon to Google Play">
        <PlayIcon />
        <div>
          <div className="b-top">Get it on</div>
          <div className="b-main">Google Play</div>
        </div>
        <span className="soon">Soon</span>
      </div>
    </div>
  )
}
