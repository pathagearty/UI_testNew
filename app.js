(() => {
  const $ = selector => document.querySelector(selector);
  const $$ = selector => [...document.querySelectorAll(selector)];
  const service = window.ClearwayDataService;

  const state = {
    workspace: null,
    currentCase: null,
    lastFocused: null,
    analyzedCaseIds: new Set()
  };

  const statusLabels = {
    supported: 'Supported',
    not_evidenced: 'Evidence needed',
    conflicting: 'Conflict found',
    unable_to_assess: 'Unable to assess',
    not_applicable: 'Not applicable',
    blocked: 'Blocked',
    pending: 'Not analyzed'
  };

  const scenarioOrder = ['needs_documentation', 'review_ready', 'conflicting_evidence', 'policy_blocked'];

  function escapeHtml(value = '') {
    return String(value).replace(/[&<>'"]/g, character => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[character]));
  }

  function formatDate(value) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value || '')) return value || '—';
    return new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', year: 'numeric' }).format(new Date(`${value}T12:00:00`));
  }

  function toneForState(workflowState) {
    if (workflowState === 'review_ready') return 'ready';
    if (['clinical_review_required', 'blocked_invalid_input'].includes(workflowState)) return 'blocked';
    return 'attention';
  }

  function hasFoundryAnalysis(record = state.currentCase) {
    return Boolean(record && record.review && record.review.resultSource === 'microsoft_foundry_agent');
  }

  function toneForCriterion(status) {
    if (status === 'supported') return 'success';
    if (status === 'not_evidenced') return 'warning';
    if (status === 'conflicting' || status === 'blocked') return 'danger';
    return 'neutral';
  }

  function option(value, label) {
    return `<option value="${escapeHtml(value)}">${escapeHtml(label)}</option>`;
  }

  function updateDataSource() {
    const status = service.getStatus();
    const node = $('#data-source');
    node.dataset.mode = status.mode;
    node.querySelector('span').textContent = status.label;
    node.title = status.lastError || 'Synthetic source records are served by the local backend; completed analysis is accepted only from Microsoft Foundry.';
  }

  function populatePatients() {
    const patients = [...state.workspace.patients].sort((a, b) => a.name.localeCompare(b.name));
    $('#patient-select').innerHTML = patients.map(patient => option(patient.id, `${patient.name} · ${patient.id}`)).join('');
    const preferred = patients.find(patient => patient.id === 'PAT-3001') || patients[0];
    $('#patient-select').value = preferred.id;
  }

  function populateCases(preferredCaseId = null) {
    const patientId = $('#patient-select').value;
    const cases = state.workspace.cases
      .filter(item => item.patientId === patientId)
      .sort((a, b) => scenarioOrder.indexOf(a.scenario) - scenarioOrder.indexOf(b.scenario));
    $('#case-select').innerHTML = cases.map(item => option(item.id, `${item.id} · ${item.procedure} · ${item.statusLabel}`)).join('');
    if (preferredCaseId && cases.some(item => item.id === preferredCaseId)) $('#case-select').value = preferredCaseId;
    return cases[0]?.id || null;
  }

  function populateLinkedContext(record) {
    $('#order-select').innerHTML = record.orders.map(order => option(order.id, `${order.id} · ${order.procedure} · ${order.codeSystem} ${order.procedureCode}`)).join('');
    $('#order-select').value = record.selectedOrderId || record.orders[0]?.id || '';
    const policyLabel = `${record.policy.id} v${record.policy.version} · ${record.policy.name}`;
    $('#policy-select').innerHTML = option(`${record.policy.id}:${record.policy.version}`, policyLabel);
  }

  async function loadSelectedCase(caseId = $('#case-select').value) {
    if (!caseId) return;
    setReviewButton(true, 'Loading case…');
    try {
      state.currentCase = await service.loadCase(caseId);
      populateLinkedContext(state.currentCase);
      updateDataSource();
      renderCase();
    } catch (error) {
      renderError('Unable to load the selected case', error.message);
    } finally {
      setReviewButton(false, 'Run Foundry evidence review');
    }
  }

  function setReviewButton(loading, label) {
    const button = $('#run-review');
    button.disabled = loading;
    button.textContent = label;
    $('#patient-select').disabled = loading;
    $('#case-select').disabled = loading;
    $('#order-select').disabled = loading;
  }

  function renderError(title, message) {
    const banner = $('#status-banner');
    banner.dataset.state = 'blocked';
    $('.status-icon').textContent = '×';
    $('#workflow-state').textContent = title;
    $('#workflow-message').textContent = message;
    showToast('The case could not be loaded');
  }

  function renderSteps() {
    const c = state.currentCase;
    ['#step-case', '#step-context', '#step-check', '#step-review'].forEach(selector => $(selector).className = '');
    $('#step-case').classList.add('complete');
    $('#step-context').classList.add(c.review.state === 'blocked_invalid_input' ? 'active' : 'complete');
    if (!hasFoundryAnalysis(c)) {
      $('#step-check').classList.add('active');
    } else if (c.review.state === 'review_ready') {
      $('#step-check').classList.add('complete');
      $('#step-review').classList.add('active');
    } else if (c.review.state !== 'blocked_invalid_input') {
      $('#step-check').classList.add('active');
    }
  }

  function renderVerificationItem(selector, label, value, itemState = 'ready') {
    const element = $(selector);
    element.dataset.state = itemState;
    const mark = itemState === 'blocked' ? '×' : itemState === 'warning' ? '!' : '✓';
    element.innerHTML = `<span class="verification-mark" aria-hidden="true">${mark}</span><span><small>${escapeHtml(label)}</small><strong title="${escapeHtml(value)}">${escapeHtml(value)}</strong></span>`;
  }

  function calculateMetrics(record) {
    const analyzed = hasFoundryAnalysis(record);
    const required = record.criteria.filter(item => item.status !== 'not_applicable');
    const supported = analyzed ? required.filter(item => item.status === 'supported').length : 0;
    const attention = analyzed ? required.filter(item => !['supported', 'not_applicable'].includes(item.status)).length : 0;
    const documentsPresent = record.documents.filter(item => item.present).length;
    return {
      analyzed,
      required: required.length,
      supported,
      attention,
      percentage: analyzed && required.length ? Math.round((supported / required.length) * 100) : 0,
      documentsPresent,
      documentsTotal: record.documents.length
    };
  }

  function renderMetrics(record) {
    const metrics = calculateMetrics(record);
    $('#requirements-percent').textContent = metrics.analyzed ? `${metrics.percentage}%` : '—';
    $('#requirements-ratio').textContent = metrics.analyzed ? `${metrics.supported} of ${metrics.required}` : 'Not analyzed';
    $('#requirements-ring').style.setProperty('--progress', `${metrics.percentage * 3.6}deg`);
    $('#documents-metric').textContent = `${metrics.documentsPresent} of ${metrics.documentsTotal}`;
    $('#documents-caption').textContent = metrics.documentsPresent === metrics.documentsTotal ? 'All expected source records are available' : `${metrics.documentsTotal - metrics.documentsPresent} expected source record${metrics.documentsTotal - metrics.documentsPresent === 1 ? '' : 's'} outstanding`;
    $('#attention-metric').textContent = metrics.analyzed ? String(metrics.attention) : '—';
    $('#policy-metric').textContent = record.policy.current ? 'Current' : 'Blocked';
    $('#policy-metric-caption').textContent = record.policy.current ? 'Effective on the request date' : 'Policy expired before request date';
    const policyCard = $('#policy-metric').closest('.metric-card');
    policyCard.dataset.state = record.policy.current ? 'ready' : 'blocked';
    policyCard.querySelector('.metric-icon').textContent = record.policy.current ? '✓' : '×';
  }

  function renderCase() {
    const c = state.currentCase;
    const order = c.orders.find(item => item.id === $('#order-select').value) || c.orders[0];
    const review = c.review;
    const statusBanner = $('#status-banner');
    const statusTone = toneForState(review.state);
    const analyzed = hasFoundryAnalysis(c);
    statusBanner.dataset.state = statusTone;
    $('.status-icon').textContent = !analyzed ? '○' : review.state === 'review_ready' ? '✓' : statusTone === 'blocked' ? '×' : '!';
    $('#workflow-state').textContent = review.stateLabel;
    $('#workflow-message').textContent = review.stateMessage;
    $('#policy-version').textContent = `${c.policy.id} · v${c.policy.version}`;
    $('#policy-effective').textContent = `${formatDate(c.policy.effectiveStart)} – ${formatDate(c.policy.effectiveEnd)}`;
    $('#procedure-pill').textContent = order.procedure;

    renderSteps();
    renderMetrics(c);
    renderVerificationItem('#case-verification', 'Patient / case linked', `${c.patient.id} · ${c.id}`);
    renderVerificationItem('#order-verification', 'Order verified', `${order.id} · ${order.codeSystem} ${order.procedureCode}`);
    renderVerificationItem('#policy-verification', 'Policy version', c.policy.current ? `${c.policy.id} v${c.policy.version} pinned` : `${c.policy.id} v${c.policy.version} expired`, c.policy.current ? 'ready' : 'blocked');
    renderVerificationItem(
      '#trace-verification',
      analyzed ? 'Foundry response trace' : 'Analysis provenance',
      analyzed ? (review.traceId || review.runId) : 'Not run · Foundry required',
      analyzed ? 'ready' : 'warning'
    );

    $('#case-facts').innerHTML = [
      ['Case ID', c.id],
      ['Patient', c.patient.name],
      ['Patient ID / MRN', `${c.patient.id} · ${c.patient.mrn}`],
      ['Order ID', order.id],
      ['Procedure', `${order.procedure} · ${order.codeSystem} ${order.procedureCode}`],
      ['Ordering clinician', order.orderingClinician],
      ['Payer / plan', `${c.coverage.payer.name} · ${c.coverage.plan.name}`],
      ['Coverage IDs', `${c.coverage.payer.id} · ${c.coverage.plan.id} · ${c.coverage.coverageId}`],
      ['Request date', formatDate(c.requestDate)],
      ['Policy hash', c.policy.contentHash]
    ].map(([key, value]) => `<div><dt>${escapeHtml(key)}</dt><dd title="${escapeHtml(value)}">${escapeHtml(value)}</dd></div>`).join('');

    const present = c.documents.filter(document => document.present).length;
    $('#document-count').textContent = `${present} of ${c.documents.length} available`;
    $('#document-list').innerHTML = c.documents.map(document => `
      <div class="document-item ${document.present ? '' : 'missing'}">
        <span class="document-icon" aria-hidden="true">${document.present ? '✓' : '!'}</span>
        <div><strong>${escapeHtml(document.name)}</strong><small>${escapeHtml(document.id)} · ${escapeHtml(document.type)} · ${escapeHtml(formatDate(document.date))}</small></div>
      </div>`).join('');

    renderCriteria();
    renderNextStep();
  }

  function renderClinicalSources(item) {
    const conflict = item.status === 'conflicting';
    const cards = (item.clinicalSources || []).map(source => `
      <div class="source-quote" data-conflict="${conflict}">
        <strong>${escapeHtml(source.label)}</strong>
        <blockquote>“${escapeHtml(source.quote)}”</blockquote>
        <small>${escapeHtml(source.documentId || '')}${source.documentId ? ' · ' : ''}${escapeHtml(source.locator)}</small>
      </div>`).join('');
    if (!cards && item.status === 'pending') {
      return '<p class="analysis-pending">No clinical evidence mapping exists yet. Run the Microsoft Foundry review.</p>';
    }
    const reason = item.whyFlagged ? `<div class="conflict-callout"><strong>Why this was flagged:</strong> ${escapeHtml(item.whyFlagged)}</div>` : '';
    return `<div class="source-stack">${cards}</div>${reason}`;
  }

  function renderCriteria() {
    const c = state.currentCase;
    const metrics = calculateMetrics(c);
    $('#checklist-summary').innerHTML = metrics.analyzed ? `
      <span><strong>${metrics.supported}</strong><small>supported</small></span>
      <span class="${metrics.attention ? 'has-attention' : ''}"><strong>${metrics.attention}</strong><small>need action</small></span>` : `
      <span><strong>—</strong><small>not analyzed</small></span>`;

    $('#criteria-list').innerHTML = c.criteria.map(item => {
      const tone = toneForCriterion(item.status);
      const expanded = ['conflicting', 'blocked'].includes(item.status) || item.resolved ? ' open' : '';
      const mark = item.status === 'pending' ? '○' : item.status === 'supported' ? '✓' : item.status === 'not_applicable' ? '–' : item.status === 'blocked' ? '×' : '!';
      return `
        <details class="criterion criterion-${tone}"${expanded}>
          <summary>
            <span class="criterion-mark" aria-hidden="true">${mark}</span>
            <span class="criterion-copy"><strong>${escapeHtml(item.title)}</strong><small>${escapeHtml(item.description)}</small></span>
            <span class="status-pill status-${tone}">${escapeHtml(statusLabels[item.status] || item.status)}</span>
          </summary>
          <div class="criterion-detail">
            <section><h3>Payer policy</h3><blockquote>“${escapeHtml(item.policyQuote)}”</blockquote><small>${escapeHtml(item.policyLocator)}</small></section>
            <section><h3>Clinical evidence</h3>${renderClinicalSources(item)}</section>
            <section class="next-evidence${item.resolved ? ' is-resolved' : ''}"><h3>${item.status === 'pending' ? 'Analysis status' : item.resolved ? 'Resolution' : 'Required action'}</h3><p>${escapeHtml(item.next)}</p></section>
          </div>
        </details>`;
    }).join('');
  }

  function renderNextStep() {
    const c = state.currentCase;
    const action = $('#primary-action');
    const summary = $('#review-letter');
    const issues = c.criteria.filter(item => ['not_evidenced', 'conflicting', 'unable_to_assess', 'blocked'].includes(item.status));
    summary.disabled = !hasFoundryAnalysis(c) || ['clinical_review_required', 'blocked_invalid_input'].includes(c.review.state);

    if (!hasFoundryAnalysis(c)) {
      $('#next-step-title').textContent = 'Run the Microsoft Foundry evidence review';
      $('#next-step-guidance').textContent = 'No evidence mapping or readiness conclusion exists yet. The backend must receive and validate a live Foundry agent response first.';
      $('#attention-list').innerHTML = '<li>Select Run Foundry evidence review to submit this bounded synthetic case to the configured Foundry agent.</li>';
      action.textContent = 'Awaiting Foundry analysis';
      action.disabled = true;
      summary.disabled = true;
    } else if (c.review.state === 'review_ready') {
      $('#next-step-title').textContent = 'Ready for clinician review';
      $('#next-step-guidance').textContent = 'Verify the source-linked evidence and clinical summary before deciding whether the package should move to submission.';
      $('#attention-list').innerHTML = '<li>No unresolved policy-evidence gaps remain.</li>';
      action.textContent = 'Send to clinician review';
      action.disabled = false;
      summary.disabled = false;
    } else if (c.review.state === 'clinical_review_required') {
      $('#next-step-title').textContent = 'Resolve the clinical conflict';
      $('#next-step-guidance').textContent = 'Both source statements remain visible. The workflow will not decide which clinical statement is correct.';
      $('#attention-list').innerHTML = issues.map(item => `<li>${escapeHtml(item.next)}</li>`).join('');
      action.textContent = 'Request clinical clarification';
      action.disabled = false;
    } else if (c.review.state === 'blocked_invalid_input') {
      $('#next-step-title').textContent = 'Resolve the policy mapping';
      $('#next-step-guidance').textContent = 'Evidence review cannot continue until the backend resolves a policy effective on the request date.';
      $('#attention-list').innerHTML = issues.map(item => `<li>${escapeHtml(item.next)}</li>`).join('');
      action.textContent = 'Review policy mapping';
      action.disabled = false;
    } else {
      $('#next-step-title').textContent = 'Complete the evidence package';
      $('#next-step-guidance').textContent = 'Collect the highlighted documentation before routing the case to a clinician.';
      $('#attention-list').innerHTML = issues.map(item => `<li>${escapeHtml(item.next)}</li>`).join('');
      action.textContent = 'Create documentation request';
      action.disabled = false;
      summary.disabled = false;
    }
  }

  function openModal(kicker, title, body, action = null) {
    state.lastFocused = document.activeElement;
    $('#modal-kicker').textContent = kicker;
    $('#modal-title').textContent = title;
    $('#modal-body').innerHTML = body;
    const primary = $('#modal-primary');
    primary.hidden = !action;
    primary.onclick = null;
    if (action) {
      primary.textContent = action.label;
      primary.onclick = action.handler;
    }
    $('#modal').classList.add('is-open');
    $('#modal').setAttribute('aria-hidden', 'false');
    $('.modal-close').focus();
  }

  function closeModal() {
    $('#modal').classList.remove('is-open');
    $('#modal').setAttribute('aria-hidden', 'true');
    $('#modal-primary').onclick = null;
    if (state.lastFocused) state.lastFocused.focus();
  }

  function showClinicalSummary() {
    const c = state.currentCase;
    if (!hasFoundryAnalysis(c)) {
      showToast('Run and validate the Foundry review first');
      return;
    }
    const order = c.orders.find(item => item.id === $('#order-select').value) || c.orders[0];
    const metrics = calculateMetrics(c);
    openModal('CLINICIAN REVIEW REQUIRED', 'Prior authorization evidence summary', `
      <article class="draft-letter">
        <dl class="modal-facts">
          <div><dt>Patient</dt><dd>${escapeHtml(c.patient.name)} · ${escapeHtml(c.patient.id)}</dd></div>
          <div><dt>Case / order</dt><dd>${escapeHtml(c.id)} · ${escapeHtml(order.id)}</dd></div>
          <div><dt>Requested service</dt><dd>${escapeHtml(order.procedure)} · ${escapeHtml(order.codeSystem)} ${escapeHtml(order.procedureCode)}</dd></div>
          <div><dt>Policy</dt><dd>${escapeHtml(c.policy.id)} v${escapeHtml(c.policy.version)}</dd></div>
        </dl>
        <p><strong>${metrics.supported} of ${metrics.required} required criteria have source-linked support.</strong></p>
        <p>This summary assists review; it does not determine medical necessity, approve or deny a request, or submit information to a payer.</p>
        <p><strong>Clinician verification and attestation are required before use.</strong></p>
      </article>`);
  }

  function handlePrimaryAction() {
    const c = state.currentCase;
    if (!hasFoundryAnalysis(c)) {
      showToast('Run and validate the Foundry review first');
      return;
    }
    if (c.review.state === 'review_ready') {
      openModal('CLINICIAN HANDOFF', 'Case prepared for clinician review', '<p>The evidence package is ready for an authorized clinician to verify. The UAT workflow records the handoff but does not submit to a payer.</p>');
    } else if (c.review.state === 'clinical_review_required') {
      openModal('CLINICAL CLARIFICATION', 'Resolve the conflicting finding', `
        <p>The Foundry review retained both cited statements and did not select which one is correct.</p>
        <p>Update the authorized source record outside this demo, then rerun the same Foundry evidence review. Synthetic clarification injection is disabled.</p>`);
    } else if (c.review.state === 'blocked_invalid_input') {
      openModal('POLICY RESOLUTION', 'Current policy required', '<p>The backend must resolve exactly one policy using payer, plan, procedure, and request date. A missing, stale, or ambiguous match remains blocked for authorized review.</p>');
    } else {
      const missing = c.criteria.filter(item => item.status === 'not_evidenced');
      openModal('DOCUMENTATION REQUEST', 'Evidence request prepared', `<p>The provider-team request contains only the unresolved requirements below. No message is sent from this UAT workspace.</p><ul>${missing.map(item => `<li>${escapeHtml(item.next)}</li>`).join('')}</ul>`);
    }
  }

  function showToast(message) {
    const toast = $('#toast');
    toast.textContent = message;
    toast.classList.add('is-visible');
    clearTimeout(showToast.timer);
    showToast.timer = setTimeout(() => toast.classList.remove('is-visible'), 2600);
  }

  async function runEvidenceReview() {
    if (!state.currentCase) return;
    const button = $('#run-review');
    const labels = ['Validating source bundle…', 'Invoking Microsoft Foundry…', 'Comparing policy and evidence…', 'Validating citations and output…'];
    setReviewButton(true, labels[0]);
    try {
      for (const label of labels) {
        button.textContent = label;
        await new Promise(resolve => setTimeout(resolve, 180));
      }
      const reviewed = await service.runEvidenceReview(state.currentCase.id, $('#order-select').value);
      if (!hasFoundryAnalysis(reviewed)) throw new Error('The backend returned no validated Microsoft Foundry provenance.');
      state.currentCase = reviewed;
      state.analyzedCaseIds.add(reviewed.id);
      $('#queue-attention').textContent = String(state.analyzedCaseIds.size);
      populateLinkedContext(state.currentCase);
      updateDataSource();
      renderCase();
      showToast('Live Microsoft Foundry evidence review complete');
    } catch (error) {
      renderError('Foundry evidence review unavailable', error.message);
      showToast(error.message);
    } finally {
      setReviewButton(false, 'Run Foundry evidence review');
    }
  }

  function wireEvents() {
    $('#patient-select').addEventListener('change', async () => {
      const firstCaseId = populateCases();
      await loadSelectedCase(firstCaseId);
    });
    $('#case-select').addEventListener('change', event => loadSelectedCase(event.target.value));
    $('#order-select').addEventListener('change', renderCase);
    $('#run-review').addEventListener('click', runEvidenceReview);
    $('#primary-action').addEventListener('click', handlePrimaryAction);
    $('#review-letter').addEventListener('click', showClinicalSummary);
    $$('[data-close-modal]').forEach(element => element.addEventListener('click', closeModal));
    document.addEventListener('keydown', event => {
      if (event.key === 'Escape' && $('#modal').classList.contains('is-open')) closeModal();
    });
  }

  async function initialize() {
    wireEvents();
    setReviewButton(true, 'Loading workspace…');
    try {
      state.workspace = await service.loadWorkspace();
      populatePatients();
      const caseId = populateCases('PA-3001');
      $('#queue-open').textContent = String(state.workspace.cases.length);
      $('#queue-attention').textContent = String(state.analyzedCaseIds.size);
      updateDataSource();
      await loadSelectedCase(caseId);
    } catch (error) {
      renderError('Workspace unavailable', error.message);
      setReviewButton(false, 'Retry');
    }
  }

  initialize();
})();
