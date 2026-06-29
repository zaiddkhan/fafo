// Thin client over the Mapbox Search Box API (suggest + retrieve), mirroring
// the Flutter app's MapboxSearchService so the admin panel resolves places the
// same way the product does. A single sessionToken groups keystrokes + the
// final retrieve into one billed session, so create one instance per picker.
//
// Docs: https://docs.mapbox.com/api/search/search-box/

const BASE = "https://api.mapbox.com/search/searchbox/v1";

export interface PlaceSuggestion {
  mapboxId: string;
  name: string;
  placeFormatted: string;
}

export interface PlacePick {
  name: string;
  address: string;
  lat: number;
  lng: number;
}

export function mapboxToken(): string {
  return import.meta.env.VITE_MAPBOX_TOKEN ?? "";
}

export function isMapboxConfigured(): boolean {
  return mapboxToken().length > 0;
}

function generateSessionToken(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

export class MapboxSearch {
  readonly sessionToken: string;

  constructor(sessionToken?: string) {
    this.sessionToken = sessionToken ?? generateSessionToken();
  }

  async suggest(
    query: string,
    opts: { signal?: AbortSignal; proximity?: { lat: number; lng: number } } = {},
  ): Promise<PlaceSuggestion[]> {
    const trimmed = query.trim();
    if (trimmed.length < 2 || !isMapboxConfigured()) return [];

    const params = new URLSearchParams({
      q: trimmed,
      access_token: mapboxToken(),
      session_token: this.sessionToken,
      limit: "7",
      types: "poi,address,place,neighborhood,locality",
    });
    if (opts.proximity) {
      params.set("proximity", `${opts.proximity.lng},${opts.proximity.lat}`);
    }

    const res = await fetch(`${BASE}/suggest?${params}`, { signal: opts.signal });
    if (!res.ok) throw new Error(`Search failed (${res.status})`);
    const data = await res.json();
    const suggestions = Array.isArray(data?.suggestions) ? data.suggestions : [];
    return suggestions
      .map((s: Record<string, unknown>): PlaceSuggestion | null => {
        const id = s.mapbox_id;
        const name = s.name;
        if (typeof id !== "string" || !id || typeof name !== "string" || !name) {
          return null;
        }
        const place = s.place_formatted;
        return {
          mapboxId: id,
          name,
          placeFormatted: typeof place === "string" ? place : "",
        };
      })
      .filter((s: PlaceSuggestion | null): s is PlaceSuggestion => s !== null);
  }

  async retrieve(suggestion: PlaceSuggestion): Promise<PlacePick | null> {
    if (!isMapboxConfigured()) return null;

    const params = new URLSearchParams({
      access_token: mapboxToken(),
      session_token: this.sessionToken,
    });
    const res = await fetch(`${BASE}/retrieve/${suggestion.mapboxId}?${params}`);
    if (!res.ok) throw new Error(`Lookup failed (${res.status})`);
    const data = await res.json();

    const feature = Array.isArray(data?.features) ? data.features[0] : null;
    const coords = feature?.geometry?.coordinates;
    if (!Array.isArray(coords) || coords.length < 2) return null;
    const lng = Number(coords[0]);
    const lat = Number(coords[1]);
    if (Number.isNaN(lat) || Number.isNaN(lng)) return null;

    const props = feature?.properties ?? {};
    const name = typeof props.name === "string" ? props.name : suggestion.name;
    const address =
      (typeof props.full_address === "string" && props.full_address) ||
      (typeof props.place_formatted === "string" && props.place_formatted) ||
      suggestion.placeFormatted ||
      "";

    return { name, address, lat, lng };
  }
}
