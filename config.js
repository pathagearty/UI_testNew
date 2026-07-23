// Deployment-specific configuration. Do not place secrets in this browser file.
// The local UAT server proxies authenticated data requests to Supabase.
window.CLEARWAY_CONFIG = Object.freeze({
  apiBaseUrl: window.location.origin,
  dataSourceLabel: 'Supabase UAT service',
  requestTimeoutMs: 8000,
  allowUatFixtureFallback: false
});
