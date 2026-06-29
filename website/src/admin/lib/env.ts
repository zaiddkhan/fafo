// Admin-panel runtime config. Firebase config lives in the shared website
// firebase module (src/firebase.ts) so it isn't duplicated here.
export const env = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8000",
  posthog: {
    key: import.meta.env.VITE_POSTHOG_KEY ?? "",
    host: import.meta.env.VITE_POSTHOG_HOST ?? "https://us.i.posthog.com",
  },
};
