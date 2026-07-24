(() => {
  const config = window.CLEARWAY_CONFIG || {};
  const baseUrl = String(config.apiBaseUrl || '').replace(/\/$/, '');
  const timeoutMs = Number(config.requestTimeoutMs || 120000);
  let lastError = null;

  async function request(path, options = {}) {
    if (!baseUrl) throw new Error('No backend API URL is configured.');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetch(`${baseUrl}${path}`, {
        credentials: 'include',
        headers: { 'Accept': 'application/json', 'Content-Type': 'application/json', ...(options.headers || {}) },
        ...options,
        signal: controller.signal
      });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) {
        const error = new Error(body.error || `Backend request failed with HTTP ${response.status}.`);
        error.code = body.code || `http_${response.status}`;
        throw error;
      }
      lastError = null;
      return body;
    } catch (error) {
      lastError = error;
      if (error.name === 'AbortError') throw new Error('The Foundry review timed out before the backend returned a result.');
      throw error;
    } finally {
      clearTimeout(timeout);
    }
  }

  const service = {
    async loadWorkspace() {
      return request('/api/v1/prior-authorizations/workspace');
    },

    async loadCase(caseId) {
      return request(`/api/v1/prior-authorization-cases/${encodeURIComponent(caseId)}`);
    },

    async runEvidenceReview(caseId, sourceOrderId) {
      return request('/api/v1/evidence-reviews', {
        method: 'POST',
        body: JSON.stringify({ case_id: caseId, source_order_id: sourceOrderId })
      });
    },

    getStatus() {
      return {
        mode: 'api',
        apiBaseUrl: baseUrl,
        lastError: lastError ? lastError.message : null,
        label: config.dataSourceLabel || 'Local synthetic sources · Foundry analysis'
      };
    }
  };

  window.ClearwayDataService = Object.freeze(service);
})();
