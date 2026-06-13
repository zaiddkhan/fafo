export const env = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? "http://localhost:8000",
  firebase: {
    apiKey: import.meta.env.VITE_FIREBASE_API_KEY ?? "",
    authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ?? "",
    projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID ?? "",
    appId: import.meta.env.VITE_FIREBASE_APP_ID ?? "",
  },
  posthog: {
    key: import.meta.env.VITE_POSTHOG_KEY ?? "",
    host: import.meta.env.VITE_POSTHOG_HOST ?? "https://us.i.posthog.com",
  },
};
