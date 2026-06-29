import { useEffect, useRef, useState } from "react";
import {
  MapboxSearch,
  isMapboxConfigured,
  type PlacePick,
  type PlaceSuggestion,
} from "@admin/lib/mapbox";

// Place-search autocomplete (Mapbox Search Box API). On select it resolves the
// chosen place to coordinates and reports them via onSelect — the parent form
// writes them into its lat/lng/name fields. The manual coordinate inputs stay
// as a fallback, so the form still works if no Mapbox token is configured.
export function PlaceSearch({
  onSelect,
  placeholder = "Search for a place…",
}: {
  onSelect: (place: PlacePick) => void;
  placeholder?: string;
}) {
  const [query, setQuery] = useState("");
  const [suggestions, setSuggestions] = useState<PlaceSuggestion[]>([]);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const search = useRef(new MapboxSearch());

  useEffect(() => {
    const q = query.trim();
    if (q.length < 2) {
      setSuggestions([]);
      return;
    }
    const controller = new AbortController();
    const timer = setTimeout(async () => {
      setLoading(true);
      setError(null);
      try {
        const results = await search.current.suggest(q, {
          signal: controller.signal,
        });
        setSuggestions(results);
        setOpen(true);
      } catch (e) {
        if ((e as Error).name !== "AbortError") {
          setError("Place search is unavailable right now.");
        }
      } finally {
        setLoading(false);
      }
    }, 250);
    return () => {
      controller.abort();
      clearTimeout(timer);
    };
  }, [query]);

  async function choose(s: PlaceSuggestion) {
    setOpen(false);
    setQuery(s.name);
    try {
      const place = await search.current.retrieve(s);
      if (place) onSelect(place);
      else setError("Couldn't resolve that place. Pick another or enter coordinates manually.");
    } catch {
      setError("Couldn't resolve that place. Pick another or enter coordinates manually.");
    }
  }

  if (!isMapboxConfigured()) {
    return (
      <div className="rounded-xl border-2 border-dashed border-ink/30 px-3 py-2 text-xs font-semibold text-ink/50">
        Place search is off — set <span className="font-mono">VITE_MAPBOX_TOKEN</span> to
        enable it. You can still enter coordinates manually below.
      </div>
    );
  }

  return (
    <div className="relative">
      <div className="relative">
        <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-ink/40">
          🔍
        </span>
        <input
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => suggestions.length > 0 && setOpen(true)}
          onBlur={() => setTimeout(() => setOpen(false), 150)}
          placeholder={placeholder}
          className="w-full rounded-xl border-[2.5px] border-ink bg-white py-2 pl-9 pr-3 text-sm font-medium text-ink outline-none transition-shadow placeholder:text-ink/40 focus:shadow-[3px_3px_0_0_#16171b]"
        />
        {loading && (
          <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-ink/40">
            …
          </span>
        )}
      </div>

      {open && suggestions.length > 0 && (
        <ul className="absolute z-10 mt-1.5 max-h-64 w-full overflow-y-auto rounded-xl border-[2.5px] border-ink bg-white shadow-[4px_4px_0_0_#16171b]">
          {suggestions.map((s) => (
            <li key={s.mapboxId}>
              <button
                type="button"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => choose(s)}
                className="block w-full border-b-2 border-ink/10 px-3 py-2 text-left last:border-b-0 hover:bg-brand-50"
              >
                <div className="text-sm font-bold text-ink">{s.name}</div>
                {s.placeFormatted && (
                  <div className="text-xs font-medium text-ink/50">
                    {s.placeFormatted}
                  </div>
                )}
              </button>
            </li>
          ))}
        </ul>
      )}

      {error && (
        <p className="mt-1 text-xs font-semibold text-[#B42318]">{error}</p>
      )}
    </div>
  );
}
