import posthog from "posthog-js";
import { env } from "./env";

let initialized = false;

export function initAnalytics() {
  if (initialized || !env.posthog.key) return;
  posthog.init(env.posthog.key, { api_host: env.posthog.host });
  initialized = true;
}

export function track(event: string, props?: Record<string, unknown>) {
  if (!initialized) return;
  posthog.capture(event, props);
}
