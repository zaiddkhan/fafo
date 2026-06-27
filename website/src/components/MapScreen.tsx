import { SearchIcon, MapIcon, BellIcon, FlagIcon } from './icons'

/** The live-map home screen shown inside the hero phone. */
export function MapScreen() {
  return (
    <>
      <div className="map-head">
        <div className="searchbar">
          <SearchIcon style={{ width: 15, height: 15 }} />
          Search your city
        </div>
        <div className="chips">
          <span className="chip on">Tonight</span>
          <span className="chip">Free</span>
          <span className="chip">Music</span>
          <span className="chip">Food</span>
        </div>
      </div>

      <div className="events-strip">
        <span className="gd" />
        18 spots popping near you right now
      </div>

      <div className="mapcanvas">
        <div className="citylabel">DOWNTOWN</div>
        <div className="pin blue" style={{ top: '22%', left: '26%' }}>🎧</div>
        <div className="pin" style={{ top: '34%', left: '62%' }}>🍜</div>
        <div className="pin" style={{ top: '58%', left: '38%' }}>🏀</div>
        <div className="pin blue" style={{ top: '50%', left: '74%' }}>🍻</div>

        <div className="preview-card">
          <div className="thumb">🎧</div>
          <div>
            <div className="pc-venue">The Warehouse · 0.4 mi</div>
            <div className="pc-title">Rooftop Set</div>
            <div className="pc-time">Tonight · 9:00 PM</div>
          </div>
          <div className="pc-rsvp">RSVP</div>
        </div>

        <div className="botnav">
          <div className="ni on">
            <MapIcon />
            <span>Map</span>
          </div>
          <BellIcon className="ni" />
          <FlagIcon className="ni" />
        </div>
      </div>
    </>
  )
}
