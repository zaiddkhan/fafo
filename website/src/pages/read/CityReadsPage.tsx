import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { Header } from '../../components/Header'
import { Footer } from '../../components/Footer'
import { fetchCityReads, isEmbedded, type Blog } from '../../lib/blogs'
import './read.css'

type Status = 'loading' | 'ready' | 'error'

function prettyCity(city: string) {
  return city.replace(/[-_]+/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}

export default function CityReadsPage() {
  const { city = '' } = useParams()
  const [blogs, setBlogs] = useState<Blog[]>([])
  const [status, setStatus] = useState<Status>('loading')

  const cityLabel = prettyCity(city)

  useEffect(() => {
    document.title = `City Reads · ${cityLabel} · FaFo`
  }, [cityLabel])

  useEffect(() => {
    let alive = true
    setStatus('loading')
    fetchCityReads(city)
      .then((data) => {
        if (!alive) return
        setBlogs(data)
        setStatus('ready')
      })
      .catch(() => {
        if (!alive) return
        setStatus('error')
      })
    return () => {
      alive = false
    }
  }, [city])

  const embedded = isEmbedded()

  return (
    <>
      {!embedded && <Header />}
      <main className="read-page">
        <div className="wrap">
          <Link to="/" className="read-back">
            <span>←</span> Back home
          </Link>

          <div className="read-head">
            <span className="eyebrow">City Reads</span>
            <h1>
              What's poppin in <span className="read-city">{cityLabel}</span>
            </h1>
            <p>Stories, guides, and the local lowdown — straight from the scene.</p>
          </div>

          {status === 'loading' && (
            <div className="read-state">
              <p>Loading city reads…</p>
            </div>
          )}

          {status === 'error' && (
            <div className="read-state">
              <h2>Something went wrong</h2>
              <p>We couldn't load the reads for this city. Please try again later.</p>
            </div>
          )}

          {status === 'ready' && blogs.length === 0 && (
            <div className="read-state">
              <h2>No city reads yet.</h2>
              <p>Check back soon — {cityLabel} stories are on the way.</p>
            </div>
          )}

          {status === 'ready' && blogs.length > 0 && (
            <div className="read-grid">
              {blogs.map((blog) => (
                <Link
                  key={blog.id}
                  to={`/read/${encodeURIComponent(city)}/${blog.id}`}
                  className="read-card"
                >
                  {blog.image_url ? (
                    <img
                      className="read-card-cover"
                      src={blog.image_url}
                      alt=""
                      loading="lazy"
                    />
                  ) : (
                    <div className="read-card-cover placeholder" aria-hidden="true">
                      📰
                    </div>
                  )}
                  <div className="read-card-body">
                    <h3>{blog.title}</h3>
                    {blog.subtitle && <p>{blog.subtitle}</p>}
                    {blog.read_time && <div className="read-meta">{blog.read_time}</div>}
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>
      </main>
      {!embedded && <Footer />}
    </>
  )
}
