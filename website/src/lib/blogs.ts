// Public, unauthenticated blog ("City Reads") data helpers.
//
// These hit the SAME backend base URL the admin panel uses (VITE_API_BASE_URL),
// but the endpoints under /blogs/public require no auth — so, unlike the admin
// `api()` helper, we deliberately send no Authorization header here.

const apiBaseUrl: string =
  import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8000";

/** A published blog post. `body` is Markdown. Fields are snake_case from the API. */
export type Blog = {
  id: string;
  city: string;
  title: string;
  subtitle?: string | null;
  body: string;
  image_url?: string | null;
  read_time?: string | null;
  published: boolean;
  created_at?: string | null;
  updated_at?: string | null;
};

/**
 * Whether the reader is being shown inside the mobile app's WebView (vs a
 * normal browser). True when the app appends `?embed=1`, or when the page is
 * running inside an Android WebView (UA contains "; wv"). Used to hide the
 * marketing site chrome (header/footer) for a clean in-app reading surface.
 */
export function isEmbedded(): boolean {
  if (typeof window === 'undefined') return false
  const params = new URLSearchParams(window.location.search)
  if (params.has('embed')) return true
  return (navigator.userAgent || '').includes('; wv')
}

export class BlogFetchError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = "BlogFetchError";
    this.status = status;
  }
}

async function getJson<T>(path: string): Promise<T> {
  const res = await fetch(apiBaseUrl + path, {
    headers: { Accept: "application/json" },
  });
  if (!res.ok) {
    let detail = res.statusText;
    try {
      const data = await res.json();
      detail = data?.detail ?? detail;
    } catch {
      /* ignore non-JSON error bodies */
    }
    throw new BlogFetchError(res.status, detail);
  }
  return (await res.json()) as T;
}

/** List published blogs for a city, most-relevant first (server-ordered). */
export async function fetchCityReads(
  city: string,
  limit = 10,
): Promise<Blog[]> {
  const params = new URLSearchParams({ city, limit: String(limit) });
  return getJson<Blog[]>(`/blogs/public?${params.toString()}`);
}

/** Fetch a single published blog by id. Throws BlogFetchError(404) if missing. */
export async function fetchBlog(id: string): Promise<Blog> {
  return getJson<Blog>(`/blogs/public/${encodeURIComponent(id)}`);
}
