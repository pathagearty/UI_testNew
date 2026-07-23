(() => {
  const config = window.CLEARWAY_CONFIG || {};
  const baseUrl = String(config.apiBaseUrl || '').replace(/\/$/, '');
  const allowFallback = config.allowUatFixtureFallback !== false;
  const timeoutMs = Number(config.requestTimeoutMs || 6000);
  let mode = baseUrl ? 'api' : 'uat-fixture';
  let lastError = null;

  const clone = value => JSON.parse(JSON.stringify(value));
  const wait = milliseconds => new Promise(resolve => setTimeout(resolve, milliseconds));

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
      if (!response.ok) throw new Error(`Backend request failed with HTTP ${response.status}.`);
      return await response.json();
    } finally {
      clearTimeout(timeout);
    }
  }

  async function withFallback(apiCall, fixtureCall) {
    if (!baseUrl) {
      mode = 'uat-fixture';
      return fixtureCall();
    }
    try {
      const result = await apiCall();
      mode = 'api';
      lastError = null;
      return result;
    } catch (error) {
      lastError = error;
      if (!allowFallback) throw error;
      mode = 'uat-fixture-fallback';
      return fixtureCall();
    }
  }

  function fixtureWorkspace() {
    return clone(window.ClearwayDemoData.workspace);
  }

  function fixtureCase(caseId) {
    const record = window.ClearwayDemoData.cases[caseId];
    if (!record) throw new Error(`Case ${caseId} was not found in the UAT dataset.`);
    return clone(record);
  }

  const service = {
    async loadWorkspace() {
      return withFallback(
        () => request('/api/v1/prior-authorizations/workspace'),
        () => fixtureWorkspace()
      );
    },

    async loadCase(caseId) {
      return withFallback(
        () => request(`/api/v1/prior-authorization-cases/${encodeURIComponent(caseId)}`),
        () => fixtureCase(caseId)
      );
    },

    async runEvidenceReview(caseId, sourceOrderId) {
      return withFallback(
        () => request('/api/v1/evidence-reviews', {
          method: 'POST',
          body: JSON.stringify({ case_id: caseId, source_order_id: sourceOrderId })
        }),
        async () => {
          await wait(850);
          return fixtureCase(caseId);
        }
      );
    },

    async addClarification(caseId, criterionId) {
      return withFallback(
        () => request(`/api/v1/prior-authorization-cases/${encodeURIComponent(caseId)}/clarifications`, {
          method: 'POST',
          body: JSON.stringify({ criterion_id: criterionId, clarification_document_id: 'DOC-UAT-CLAR-3003' })
        }),
        async () => {
          await wait(450);
          const record = fixtureCase(caseId);
          const item = record.criteria.find(entry => entry.id === criterionId);
          if (item) {
            item.status = 'supported';
            item.resolved = true;
            item.whyFlagged = '';
            item.clinicalSources.push({
              label: 'Signed clinician clarification',
              quote: 'The examination finding is clarified as a reduced right ankle reflex; the symmetric-reflex entry was entered in error.',
              locator: 'DOC-UAT-CLAR-3003 · signed clarification'
            });
            item.next = 'Resolved by signed clarification. Original conflicting sources remain visible in the audit history.';
          }
          record.documents.push({ id: 'DOC-UAT-CLAR-3003', name: 'Signed clinician clarification', date: '2026-07-23', type: 'Clarification', present: true });
          record.review = {
            runId: 'run_uat_1045_b', traceId: 'trc_uat_1045_b', state: 'review_ready',
            stateLabel: 'Ready for clinician review',
            stateMessage: 'A signed clarification resolved the conflicting finding. The source records and resolution remain available for clinician review.'
          };
          return record;
        }
      );
    },

    getStatus() {
      return {
        mode,
        apiBaseUrl: baseUrl,
        lastError: lastError ? lastError.message : null,
        label: mode === 'api' ? (config.dataSourceLabel || 'Connected data service') : mode === 'uat-fixture-fallback' ? 'UAT data · API fallback' : 'UAT data service'
      };
    }
  };

  window.ClearwayDataService = Object.freeze(service);
})();
