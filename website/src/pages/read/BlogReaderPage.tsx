import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import { Header } from '../../components/Header'
import { Footer } from '../../components/Footer'
import { fetchBlog, isEmbedded, BlogFetchError, type Blog } from '../../lib/blogs'
import './read.css'

type Status = 'loading' | 'ready' | 'notfound' | 'error'

export default function BlogReaderPage() {
  const { city = '', id = '' } = useParams()
  const [blog, setBlog] = useState<Blog | null>(null)
  const [status, setStatus] = useState<Status>('loading')

  const backTo = `/read/${encodeURIComponent(city)}`

  useEffect(() => {
    let alive = true
    setStatus('loading')
    fetchBlog(id)
      .then((data) => {
        if (!alive) return
        setBlog(data)
        setStatus('ready')
      })
      .catch((err) => {
        if (!alive) return
        if (err instanceof BlogFetchError && err.status === 404) {
          setStatus('notfound')
        } else {
          setStatus('error')
        }
      })
    return () => {
      alive = false
    }
  }, [id])

  useEffect(() => {
    if (blog) document.title = `${blog.title} · FaFo`
    else document.title = 'City Reads · FaFo'
    return () => {
      document.title = 'FaFo'
    }
  }, [blog])

  const embedded = isEmbedded()

  return (
    <>
      {!embedded && <Header />}
      <main className="read-page">
        <div className="wrap">
          {!embedded && (
            <Link to={backTo} className="read-back">
              <span>←</span> All city reads
            </Link>
          )}

          {status === 'loading' && (
            <div className="read-state">
              <p>Loading…</p>
            </div>
          )}

          {status === 'notfound' && (
            <div className="read-state">
              <h2>Story not found</h2>
              <p>This read may have been unpublished or moved.</p>
            </div>
          )}

          {status === 'error' && (
            <div className="read-state">
              <h2>Something went wrong</h2>
              <p>We couldn't load this story. Please try again later.</p>
            </div>
          )}

          {status === 'ready' && blog && (
            <article className="read-article">
              {blog.image_url ? (
                <img className="read-hero" src={blog.image_url} alt="" />
              ) : (
                <div className="read-hero placeholder" aria-hidden="true">
                  📰
                </div>
              )}

              <h1>{blog.title}</h1>
              {blog.subtitle && <p className="read-subtitle">{blog.subtitle}</p>}

              <div className="read-article-meta">
                {blog.read_time && <span>{blog.read_time}</span>}
              </div>

              <div className="read-prose">
                <ReactMarkdown
                  remarkPlugins={[remarkGfm]}
                  components={{
                    table: ({ node, ...props }) => (
                      <div className="read-prose-scroll">
                        <table {...props} />
                      </div>
                    ),
                    a: ({ node, ...props }) => (
                      <a target="_blank" rel="noreferrer" {...props} />
                    ),
                  }}
                >
                  {blog.body}
                </ReactMarkdown>
              </div>
            </article>
          )}
        </div>
      </main>
      {!embedded && <Footer />}
    </>
  )
}
