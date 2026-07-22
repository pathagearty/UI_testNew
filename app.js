const cases = {
  'SYN-PA-1042': {
    id: 'SYN-PA-1042',
    procedure: 'Lumbar spine MRI',
    cpt: '72148',
    payer: 'HealthPlus (fictional)',
    patient: 'Morgan Lee (synthetic)',
    requestDate: '2026-07-21',
    policy: 'RAD-201',
    version: '2026.1',
    state: 'more_information_required',
    stateLabel: 'Missing information',
    stateMessage: 'The case is not ready for submission review because required treatment evidence is missing and one clinical finding needs clarification.',
    documents: [
      { name: 'Progress note', date: '2026-07-14', present: true },
      { name: 'Imaging order', date: '2026-07-18', present: true },
      { name: 'Physical therapy summary', date: 'Not supplied', present: false }
    ],
    criteria: [
      { id: 'C1', title: 'Symptoms documented for required duration', description: 'The policy requires symptoms to continue beyond the defined period.', status: 'supported', policyQuote: 'Symptoms persist for at least six weeks despite initial conservative management.', policyLocator: 'RAD-201 · page 3 · section 2.1', clinicalQuote: 'Low-back pain with right-sided radicular symptoms has persisted for approximately eight weeks.', clinicalLocator: 'Progress note · paragraph 4', next: 'No additional information identified for this requirement.' },
      { id: 'C2', title: 'Conservative treatment documented', description: 'The treatment course and the patient response must be included.', status: 'not_evidenced', policyQuote: 'The record must document at least six weeks of provider-directed conservative treatment and response.', policyLocator: 'RAD-201 · page 4 · section 2.2', clinicalQuote: 'Patient reports trying home exercises and over-the-counter medication.', clinicalLocator: 'Progress note · paragraph 7', next: 'Provide treatment dates, the provider-directed modality and the documented response.' },
      { id: 'C3', title: 'Neurologic findings are consistent', description: 'The clinical record should contain consistent objective findings.', status: 'conflicting', policyQuote: 'Objective neurologic deficit or progressive symptoms may support advanced imaging.', policyLocator: 'RAD-201 · page 4 · section 2.3', clinicalQuote: 'The assessment records a reduced right ankle reflex, while the examination records symmetric reflexes.', clinicalLocator: 'Progress note · paragraphs 9 and 12', next: 'Ask the clinician to clarify the conflicting examination findings.' },
      { id: 'C4', title: 'Red-flag exception', description: 'Urgent red-flag criteria are checked separately.', status: 'not_applicable', policyQuote: 'Red-flag findings may bypass conservative-treatment duration requirements.', policyLocator: 'RAD-201 · page 2 · section 1.4', clinicalQuote: 'No red-flag finding is documented.', clinicalLocator: 'Progress note · paragraph 10', next: 'No red-flag exception is being used for this request.' }
    ]
  },
  'SYN-PA-1043': {
    id: 'SYN-PA-1043',
    procedure: 'Lumbar spine MRI',
    cpt: '72148',
    payer: 'HealthPlus (fictional)',
    patient: 'Taylor Jordan (synthetic)',
    requestDate: '2026-07-21',
    policy: 'RAD-201',
    version: '2026.1',
    state: 'review_ready',
    stateLabel: 'Ready for clinician review',
    stateMessage: 'The required evidence categories are present and source-linked; a clinician must verify the package before any submission.',
    documents: [
      { name: 'Progress note', date: '2026-07-12', present: true },
      { name: 'Physical therapy discharge summary', date: '2026-07-10', present: true },
      { name: 'Imaging order', date: '2026-07-18', present: true }
    ],
    criteria: [
      { id: 'C1', title: 'Symptoms documented for required duration', description: 'The policy requires symptoms to continue beyond the defined period.', status: 'supported', policyQuote: 'Symptoms persist for at least six weeks despite initial conservative management.', policyLocator: 'RAD-201 · page 3 · section 2.1', clinicalQuote: 'Symptoms have persisted for ten weeks.', clinicalLocator: 'Progress note · paragraph 3', next: 'No additional information identified for this requirement.' },
      { id: 'C2', title: 'Conservative treatment documented', description: 'The treatment course and the patient response must be included.', status: 'supported', policyQuote: 'The record must document at least six weeks of provider-directed conservative treatment and response.', policyLocator: 'RAD-201 · page 4 · section 2.2', clinicalQuote: 'Eight provider-directed physical therapy visits were completed from May 5 through June 30 with limited improvement.', clinicalLocator: 'PT summary · paragraphs 2–5', next: 'No additional information identified for this requirement.' },
      { id: 'C3', title: 'Neurologic findings are consistent', description: 'The clinical record should contain consistent objective findings.', status: 'supported', policyQuote: 'Objective neurologic deficit or progressive symptoms may support advanced imaging.', policyLocator: 'RAD-201 · page 4 · section 2.3', clinicalQuote: 'Right ankle dorsiflexion strength is documented as 4/5 on two examinations.', clinicalLocator: 'Progress note · paragraphs 8 and 11', next: 'No additional information identified for this requirement.' },
      { id: 'C4', title: 'Red-flag exception', description: 'Urgent red-flag criteria are checked separately.', status: 'not_applicable', policyQuote: 'Red-flag findings may bypass conservative-treatment duration requirements.', policyLocator: 'RAD-201 · page 2 · section 1.4', clinicalQuote: 'No red-flag finding is documented.', clinicalLocator: 'Progress note · paragraph 9', next: 'No red-flag exception is being used for this request.' }
    ]
  },
  'SYN-PA-1044': {
    id: 'SYN-PA-1044',
    procedure: 'Lumbar spine MRI',
    cpt: '72148',
    payer: 'HealthPlus (fictional)',
    patient: 'Casey Kim (synthetic)',
    requestDate: '2026-07-21',
    policy: 'RAD-201',
    version: '2025.3',
    state: 'blocked_invalid_input',
    stateLabel: 'Review blocked',
    stateMessage: 'The supplied policy version expired before the request date, so the case was stopped before clinical evidence review.',
    documents: [
      { name: 'Progress note', date: '2026-07-20', present: true },
      { name: 'Imaging order', date: '2026-07-20', present: true },
      { name: 'Policy RAD-201 · version 2025.3', date: 'Expired', present: false }
    ],
    criteria: [
      { id: 'G0', title: 'Current payer policy selected', description: 'The policy must be valid on the request date.', status: 'blocked', policyQuote: 'Version 2025.3 effective through 2025-12-31.', policyLocator: 'RAD-201 · policy metadata', clinicalQuote: 'Request date: 2026-07-21.', clinicalLocator: 'Case intake', next: 'Select and pin the policy version effective on the request date, then run the review again.' }
    ]
  }
};

const statusLabels = {
  supported: 'Found',
  not_evidenced: 'Missing',
  conflicting: 'Needs clarification',
  unable_to_assess: 'Unable to assess',
  not_applicable: 'Not required',
  blocked: 'Blocked'
};

let currentCase = cases['SYN-PA-1042'];
let lastFocused = null;

const $ = selector => document.querySelector(selector);
const $$ = selector => [...document.querySelectorAll(selector)];

function escapeHtml(value = '') {
  return String(value).replace(/[&<>'"]/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;' }[char]));
}

function toneForState(state) {
  if (state === 'review_ready') return 'ready';
  if (state === 'blocked_invalid_input') return 'blocked';
  return 'attention';
}

function toneForCriterion(status) {
  if (status === 'supported') return 'success';
  if (status === 'not_evidenced') return 'warning';
  if (status === 'conflicting' || status === 'blocked') return 'danger';
  return 'neutral';
}

function renderCase() {
  const c = currentCase;
  const statusBanner = $('#status-banner');
  statusBanner.dataset.state = toneForState(c.state);
  $('.status-icon').textContent = c.state === 'review_ready' ? '✓' : c.state === 'blocked_invalid_input' ? '×' : '!';
  $('#workflow-state').textContent = c.stateLabel;
  $('#workflow-message').textContent = c.stateMessage;
  $('#policy-version').textContent = `${c.policy} · ${c.version}`;
  $('#procedure-pill').textContent = c.procedure;

  $('#case-facts').innerHTML = [
    ['Case ID', c.id],
    ['Patient', c.patient],
    ['Procedure', `${c.procedure} · CPT ${c.cpt}`],
    ['Payer', c.payer],
    ['Request date', c.requestDate]
  ].map(([key, value]) => `<div><dt>${escapeHtml(key)}</dt><dd>${escapeHtml(value)}</dd></div>`).join('');

  $('#document-count').textContent = `${c.documents.filter(document => document.present).length} of ${c.documents.length} supplied`;
  $('#document-list').innerHTML = c.documents.map(document => `
    <div class="document-item ${document.present ? '' : 'missing'}">
      <span class="document-icon" aria-hidden="true">${document.present ? '✓' : '!'}</span>
      <div><strong>${escapeHtml(document.name)}</strong><small>${escapeHtml(document.date)}</small></div>
    </div>`).join('');

  renderCriteria();
  renderNextStep();
}

function renderCriteria() {
  const c = currentCase;
  const required = c.criteria.filter(item => item.status !== 'not_applicable');
  const supported = required.filter(item => item.status === 'supported').length;
  const attention = required.filter(item => !['supported', 'not_applicable'].includes(item.status)).length;

  $('#checklist-summary').innerHTML = `
    <span><strong>${supported}</strong><small>found</small></span>
    <span class="${attention ? 'has-attention' : ''}"><strong>${attention}</strong><small>need attention</small></span>`;

  $('#criteria-list').innerHTML = c.criteria.map(item => {
    const tone = toneForCriterion(item.status);
    return `
      <details class="criterion criterion-${tone}">
        <summary>
          <span class="criterion-mark" aria-hidden="true">${item.status === 'supported' ? '✓' : item.status === 'not_applicable' ? '–' : item.status === 'blocked' ? '×' : '!'}</span>
          <span class="criterion-copy"><strong>${escapeHtml(item.title)}</strong><small>${escapeHtml(item.description)}</small></span>
          <span class="status-pill status-${tone}">${escapeHtml(statusLabels[item.status])}</span>
        </summary>
        <div class="criterion-detail">
          <section><h3>Payer policy</h3><blockquote>“${escapeHtml(item.policyQuote)}”</blockquote><small>${escapeHtml(item.policyLocator)}</small></section>
          <section><h3>Supplied record</h3><blockquote>“${escapeHtml(item.clinicalQuote)}”</blockquote><small>${escapeHtml(item.clinicalLocator)}</small></section>
          <section class="next-evidence"><h3>What to do</h3><p>${escapeHtml(item.next)}</p></section>
        </div>
      </details>`;
  }).join('');
}

function renderNextStep() {
  const c = currentCase;
  const actionButton = $('#primary-action');
  const letterButton = $('#review-letter');
  const issues = c.criteria.filter(item => ['not_evidenced', 'conflicting', 'unable_to_assess', 'blocked'].includes(item.status));

  if (c.state === 'review_ready') {
    $('#next-step-title').textContent = 'Ready for clinician review';
    $('#next-step-guidance').textContent = 'A clinician should verify the evidence and draft letter before deciding whether the provider should submit the request.';
    $('#attention-list').innerHTML = '<li>No unresolved policy-evidence gaps were identified in this synthetic example.</li>';
    actionButton.textContent = 'Send to clinician review';
    actionButton.disabled = false;
    letterButton.disabled = false;
  } else if (c.state === 'blocked_invalid_input') {
    $('#next-step-title').textContent = 'Correct the policy selection';
    $('#next-step-guidance').textContent = 'The case cannot be reviewed until the current payer policy is selected.';
    $('#attention-list').innerHTML = issues.map(item => `<li>${escapeHtml(item.next)}</li>`).join('');
    actionButton.textContent = 'Select current policy';
    actionButton.disabled = false;
    letterButton.disabled = true;
  } else {
    $('#next-step-title').textContent = 'Complete the submission package';
    $('#next-step-guidance').textContent = 'Resolve the highlighted gaps before sending the package to a clinician for final review.';
    $('#attention-list').innerHTML = issues.map(item => `<li>${escapeHtml(item.next)}</li>`).join('');
    actionButton.textContent = 'Request missing documentation';
    actionButton.disabled = false;
    letterButton.disabled = false;
  }
}

function openModal(kicker, title, body) {
  lastFocused = document.activeElement;
  $('#modal-kicker').textContent = kicker;
  $('#modal-title').textContent = title;
  $('#modal-body').innerHTML = body;
  $('#modal').classList.add('is-open');
  $('#modal').setAttribute('aria-hidden', 'false');
  $('.modal-close').focus();
}

function closeModal() {
  $('#modal').classList.remove('is-open');
  $('#modal').setAttribute('aria-hidden', 'true');
  if (lastFocused) lastFocused.focus();
}

function showLetter() {
  const c = currentCase;
  const warning = c.state === 'review_ready'
    ? 'The supplied documents contain source-linked evidence for the checklist shown in the workspace.'
    : 'The record contains unresolved documentation gaps or conflicts and should not be submitted in its current form.';
  openModal('DRAFT · CLINICIAN REVIEW REQUIRED', 'Medical necessity letter', `
    <article class="draft-letter">
      <p><strong>To the reviewing organization:</strong></p>
      <p>This synthetic package requests review of a ${escapeHtml(c.procedure)} for ${escapeHtml(c.patient)}. The supplied evidence has been compared with ${escapeHtml(c.policy)} version ${escapeHtml(c.version)}.</p>
      <p>${escapeHtml(warning)}</p>
      <p><strong>Clinician name and attestation required before use.</strong></p>
    </article>`);
}

function handlePrimaryAction() {
  const c = currentCase;
  if (c.state === 'review_ready') {
    openModal('HUMAN REVIEW', 'Case prepared for clinician review', '<p>This sample records a workflow handoff only. The clinician must verify the evidence and letter before deciding whether to submit.</p>');
  } else if (c.state === 'blocked_invalid_input') {
    openModal('POLICY REQUIRED', 'Select the current payer policy', '<p>In the integrated workflow, the provider user would select or confirm the policy version effective on the request date before running the review again.</p>');
  } else {
    openModal('DOCUMENTATION REQUEST', 'Missing information identified', `<p>This sample would prepare an internal documentation request for the provider team; it does not contact the patient or payer.</p><ul>${c.criteria.filter(item => ['not_evidenced', 'conflicting'].includes(item.status)).map(item => `<li>${escapeHtml(item.next)}</li>`).join('')}</ul>`);
  }
}

function showToast(message) {
  const toast = $('#toast');
  toast.textContent = message;
  toast.classList.add('is-visible');
  clearTimeout(showToast.timer);
  showToast.timer = setTimeout(() => toast.classList.remove('is-visible'), 2400);
}

$('#case-select').addEventListener('change', event => {
  currentCase = cases[event.target.value];
  renderCase();
  showToast(`${currentCase.id} loaded`);
});

$('#run-review').addEventListener('click', event => {
  const button = event.currentTarget;
  const original = button.textContent;
  button.disabled = true;
  button.textContent = 'Reviewing…';
  setTimeout(() => {
    button.disabled = false;
    button.textContent = original;
    renderCase();
    showToast('Synthetic review complete');
  }, 650);
});

$('#primary-action').addEventListener('click', handlePrimaryAction);
$('#review-letter').addEventListener('click', showLetter);
$$('[data-close-modal]').forEach(element => element.addEventListener('click', closeModal));
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && $('#modal').classList.contains('is-open')) closeModal();
});

renderCase();
