(() => {
  const policy = (version = '2026.1', current = true) => ({
    id: 'RAD-201',
    version,
    name: 'Advanced Imaging — Lumbar Spine MRI',
    effectiveStart: current ? '2026-01-01' : '2025-01-01',
    effectiveEnd: current ? '2026-12-31' : '2025-12-31',
    contentHash: current ? 'sha256:uat-rad201-2026-1' : 'sha256:uat-rad201-2025-3',
    current
  });

  const coverage = {
    payer: { id: 'PAY-HP-01', name: 'HealthPlus' },
    plan: { id: 'PLAN-PPO-02', name: 'Commercial PPO' },
    coverageId: 'COV-UAT-02'
  };

  const criterion = (id, title, description, status, policyQuote, policyLocator, clinicalSources, next, extras = {}) => ({
    id, title, description, status, policyQuote, policyLocator, clinicalSources, next, ...extras
  });

  const commonCriteria = patientNote => [
    criterion('C1', 'Symptoms documented for required duration', 'Symptoms must continue beyond the policy-defined period.', 'supported',
      'Symptoms persist for at least six weeks despite initial conservative management.', 'RAD-201 · page 3 · section 2.1',
      [{ label: 'Progress note', quote: patientNote.duration, locator: patientNote.durationLocator }],
      'No additional information identified for this requirement.'),
    criterion('C4', 'Red-flag exception', 'Urgent red-flag criteria are evaluated separately.', 'not_applicable',
      'Red-flag findings may bypass conservative-treatment duration requirements.', 'RAD-201 · page 2 · section 1.4',
      [{ label: 'Progress note', quote: 'No red-flag finding is documented.', locator: patientNote.redFlagLocator }],
      'No red-flag exception is being used for this request.')
  ];

  const cases = {
    'PA-1042': {
      id: 'PA-1042', scenario: 'needs_documentation', requestDate: '2026-07-21',
      patient: { id: 'PAT-2042', name: 'Morgan Lee', mrn: 'MRN-82042', dateOfBirth: '1982-04-19' },
      orders: [{ id: 'ORD-1042', procedure: 'Lumbar spine MRI', procedureCode: '72148', codeSystem: 'CPT', orderedDate: '2026-07-18', orderingClinician: 'Dr. Elena Brooks', status: 'Active' }],
      selectedOrderId: 'ORD-1042', coverage, policy: policy(),
      review: {
        runId: 'run_uat_1042', traceId: 'trc_uat_1042', state: 'more_information_required', stateLabel: 'Documentation required',
        stateMessage: 'Two requirements are supported. Treatment dates and response are still needed before clinician review.'
      },
      documents: [
        { id: 'DOC-NOTE-1042', name: 'Progress note', date: '2026-07-14', type: 'Clinical note', present: true },
        { id: 'DOC-ORDER-1042', name: 'Imaging order', date: '2026-07-18', type: 'Order', present: true },
        { id: 'DOC-PT-1042', name: 'Physical therapy summary', date: 'Not received', type: 'Treatment record', present: false }
      ],
      criteria: [
        ...commonCriteria({ duration: 'Low-back pain with right-sided radicular symptoms has persisted for approximately eight weeks.', durationLocator: 'DOC-NOTE-1042 · paragraph 4', redFlagLocator: 'DOC-NOTE-1042 · paragraph 10' }).slice(0, 1),
        criterion('C2', 'Conservative treatment documented', 'Treatment course, dates, and patient response must be included.', 'not_evidenced',
          'The record must document at least six weeks of provider-directed conservative treatment and response.', 'RAD-201 · page 4 · section 2.2',
          [{ label: 'Progress note', quote: 'Patient reports trying home exercises and over-the-counter medication.', locator: 'DOC-NOTE-1042 · paragraph 7' }],
          'Provide treatment dates, the provider-directed modality, and the documented response.'),
        criterion('C3', 'Neurologic findings are consistent', 'The clinical record should contain consistent objective findings.', 'supported',
          'Objective neurologic deficit or progressive symptoms may support advanced imaging.', 'RAD-201 · page 4 · section 2.3',
          [{ label: 'Progress note', quote: 'Right ankle dorsiflexion strength is documented as 4/5 on examination.', locator: 'DOC-NOTE-1042 · paragraph 9' }],
          'No additional information identified for this requirement.'),
        ...commonCriteria({ duration: '', durationLocator: '', redFlagLocator: 'DOC-NOTE-1042 · paragraph 10' }).slice(1)
      ]
    },
    'PA-1043': {
      id: 'PA-1043', scenario: 'review_ready', requestDate: '2026-07-21',
      patient: { id: 'PAT-2043', name: 'Taylor Jordan', mrn: 'MRN-82043', dateOfBirth: '1977-11-08' },
      orders: [{ id: 'ORD-1043', procedure: 'Lumbar spine MRI', procedureCode: '72148', codeSystem: 'CPT', orderedDate: '2026-07-18', orderingClinician: 'Dr. Elena Brooks', status: 'Active' }],
      selectedOrderId: 'ORD-1043', coverage, policy: policy(),
      review: {
        runId: 'run_uat_1043', traceId: 'trc_uat_1043', state: 'review_ready', stateLabel: 'Ready for clinician review',
        stateMessage: 'All required evidence categories are present and source-linked. A clinician must verify the package before submission.'
      },
      documents: [
        { id: 'DOC-NOTE-1043', name: 'Progress note', date: '2026-07-12', type: 'Clinical note', present: true },
        { id: 'DOC-PT-1043', name: 'Physical therapy discharge summary', date: '2026-07-10', type: 'Treatment record', present: true },
        { id: 'DOC-ORDER-1043', name: 'Imaging order', date: '2026-07-18', type: 'Order', present: true }
      ],
      criteria: [
        criterion('C1', 'Symptoms documented for required duration', 'Symptoms must continue beyond the policy-defined period.', 'supported',
          'Symptoms persist for at least six weeks despite initial conservative management.', 'RAD-201 · page 3 · section 2.1',
          [{ label: 'Progress note', quote: 'Symptoms have persisted for ten weeks.', locator: 'DOC-NOTE-1043 · paragraph 3' }], 'No additional information identified for this requirement.'),
        criterion('C2', 'Conservative treatment documented', 'Treatment course, dates, and patient response must be included.', 'supported',
          'The record must document at least six weeks of provider-directed conservative treatment and response.', 'RAD-201 · page 4 · section 2.2',
          [{ label: 'PT discharge summary', quote: 'Eight provider-directed physical therapy visits were completed from May 5 through June 30 with limited improvement.', locator: 'DOC-PT-1043 · paragraphs 2–5' }], 'No additional information identified for this requirement.'),
        criterion('C3', 'Neurologic findings are consistent', 'The clinical record should contain consistent objective findings.', 'supported',
          'Objective neurologic deficit or progressive symptoms may support advanced imaging.', 'RAD-201 · page 4 · section 2.3',
          [{ label: 'Progress note', quote: 'Right ankle dorsiflexion strength is documented as 4/5 on two examinations.', locator: 'DOC-NOTE-1043 · paragraphs 8 and 11' }], 'No additional information identified for this requirement.'),
        criterion('C4', 'Red-flag exception', 'Urgent red-flag criteria are evaluated separately.', 'not_applicable',
          'Red-flag findings may bypass conservative-treatment duration requirements.', 'RAD-201 · page 2 · section 1.4',
          [{ label: 'Progress note', quote: 'No red-flag finding is documented.', locator: 'DOC-NOTE-1043 · paragraph 9' }], 'No red-flag exception is being used for this request.')
      ]
    },
    'PA-1045': {
      id: 'PA-1045', scenario: 'conflicting_evidence', requestDate: '2026-07-21',
      patient: { id: 'PAT-2045', name: 'Avery Patel', mrn: 'MRN-82045', dateOfBirth: '1990-02-27' },
      orders: [{ id: 'ORD-1045', procedure: 'Lumbar spine MRI', procedureCode: '72148', codeSystem: 'CPT', orderedDate: '2026-07-18', orderingClinician: 'Dr. Elena Brooks', status: 'Active' }],
      selectedOrderId: 'ORD-1045', coverage, policy: policy(),
      review: {
        runId: 'run_uat_1045_a', traceId: 'trc_uat_1045_a', state: 'clinical_review_required', stateLabel: 'Clinical clarification required',
        stateMessage: 'Two clinical records disagree about the same neurologic finding. Both sources are preserved and automatic progression is stopped.'
      },
      documents: [
        { id: 'DOC-NOTE-1045', name: 'Progress note assessment', date: '2026-07-14', type: 'Clinical note', present: true },
        { id: 'DOC-EXAM-1045', name: 'Neurologic examination', date: '2026-07-14', type: 'Exam', present: true },
        { id: 'DOC-ORDER-1045', name: 'Imaging order', date: '2026-07-18', type: 'Order', present: true }
      ],
      criteria: [
        criterion('C1', 'Symptoms documented for required duration', 'Symptoms must continue beyond the policy-defined period.', 'supported',
          'Symptoms persist for at least six weeks despite initial conservative management.', 'RAD-201 · page 3 · section 2.1',
          [{ label: 'Progress note', quote: 'Radicular symptoms have continued for nine weeks.', locator: 'DOC-NOTE-1045 · paragraph 3' }], 'No additional information identified for this requirement.'),
        criterion('C2', 'Conservative treatment documented', 'Treatment course, dates, and patient response must be included.', 'supported',
          'The record must document at least six weeks of provider-directed conservative treatment and response.', 'RAD-201 · page 4 · section 2.2',
          [{ label: 'Progress note', quote: 'Six weeks of provider-directed physical therapy produced limited improvement.', locator: 'DOC-NOTE-1045 · paragraph 6' }], 'No additional information identified for this requirement.'),
        criterion('C3', 'Neurologic findings are consistent', 'The clinical record should contain consistent objective findings.', 'conflicting',
          'Objective neurologic deficit or progressive symptoms may support advanced imaging.', 'RAD-201 · page 4 · section 2.3',
          [
            { label: 'Progress note assessment', quote: 'Right ankle reflex is reduced.', locator: 'DOC-NOTE-1045 · paragraph 9' },
            { label: 'Neurologic examination', quote: 'Lower-extremity reflexes are symmetric.', locator: 'DOC-EXAM-1045 · finding 4' }
          ], 'Ask the clinician to clarify the finding before the case moves forward.',
          { whyFlagged: 'The records disagree about the same neurologic finding.' }),
        criterion('C4', 'Red-flag exception', 'Urgent red-flag criteria are evaluated separately.', 'not_applicable',
          'Red-flag findings may bypass conservative-treatment duration requirements.', 'RAD-201 · page 2 · section 1.4',
          [{ label: 'Progress note', quote: 'No red-flag finding is documented.', locator: 'DOC-NOTE-1045 · paragraph 10' }], 'No red-flag exception is being used for this request.')
      ]
    },
    'PA-1044': {
      id: 'PA-1044', scenario: 'policy_blocked', requestDate: '2026-07-21',
      patient: { id: 'PAT-2044', name: 'Casey Kim', mrn: 'MRN-82044', dateOfBirth: '1985-08-15' },
      orders: [{ id: 'ORD-1044', procedure: 'Lumbar spine MRI', procedureCode: '72148', codeSystem: 'CPT', orderedDate: '2026-07-20', orderingClinician: 'Dr. Elena Brooks', status: 'Active' }],
      selectedOrderId: 'ORD-1044', coverage, policy: policy('2025.3', false),
      review: {
        runId: 'run_uat_1044', traceId: 'trc_uat_1044', state: 'blocked_invalid_input', stateLabel: 'Policy validation required',
        stateMessage: 'The linked policy expired before the request date. Evidence review is blocked until the service resolves a current policy.'
      },
      documents: [
        { id: 'DOC-NOTE-1044', name: 'Progress note', date: '2026-07-20', type: 'Clinical note', present: true },
        { id: 'DOC-ORDER-1044', name: 'Imaging order', date: '2026-07-20', type: 'Order', present: true },
        { id: 'DOC-POLICY-1044', name: 'Policy RAD-201 · version 2025.3', date: 'Expired', type: 'Policy', present: false }
      ],
      criteria: [
        criterion('G0', 'Current payer policy resolved', 'The policy must be effective on the request date.', 'blocked',
          'Version 2025.3 effective through 2025-12-31.', 'RAD-201 · policy metadata',
          [{ label: 'Case intake', quote: 'Request date: 2026-07-21.', locator: 'PA-1044 · intake record' }],
          'Resolve and pin the policy version effective on the request date, then run the review again.')
      ]
    }
  };

  const scenarioLabels = {
    needs_documentation: 'Needs documentation',
    review_ready: 'Ready for clinician review',
    conflicting_evidence: 'Conflicting evidence',
    policy_blocked: 'Policy validation required'
  };

  const workspace = {
    patients: Object.values(cases).map(item => ({ ...item.patient })),
    cases: Object.values(cases).map(item => ({
      id: item.id,
      patientId: item.patient.id,
      orderIds: item.orders.map(order => order.id),
      procedure: item.orders[0].procedure,
      scenario: item.scenario,
      statusLabel: scenarioLabels[item.scenario],
      requestDate: item.requestDate
    }))
  };

  window.ClearwayDemoData = Object.freeze({ workspace, cases });
})();
