-- Five fully synthetic Clearway UAT cases.
-- Distribution: 2 ready, 2 missing information, 1 conflicting information.

begin;

insert into public.clearway_patients (patient_id, display_name, mrn, date_of_birth) values
  ('PAT-3001', 'Morgan Lee', 'MRN-UAT-83001', '1982-04-19'),
  ('PAT-3002', 'Taylor Jordan', 'MRN-UAT-83002', '1958-11-08'),
  ('PAT-3003', 'Avery Patel', 'MRN-UAT-83003', '1971-02-27'),
  ('PAT-3004', 'Casey Kim', 'MRN-UAT-83004', '1989-08-15'),
  ('PAT-3005', 'Jordan Rivera', 'MRN-UAT-83005', '1966-06-03');

insert into public.clearway_payers (payer_id, payer_name) values
  ('PAY-SHP-01', 'Summit Health Plan');

insert into public.clearway_plans (plan_id, payer_id, plan_name, plan_type) values
  ('PLAN-SHP-PPO', 'PAY-SHP-01', 'Summit Choice PPO', 'Commercial PPO'),
  ('PLAN-SHP-HMO', 'PAY-SHP-01', 'Summit Coordinated HMO', 'Commercial HMO');

insert into public.clearway_coverages (coverage_id, patient_id, plan_id, member_id, effective_start, effective_end) values
  ('COV-3001', 'PAT-3001', 'PLAN-SHP-PPO', 'MEM-UAT-3001', '2026-01-01', '2026-12-31'),
  ('COV-3002', 'PAT-3002', 'PLAN-SHP-HMO', 'MEM-UAT-3002', '2026-01-01', '2026-12-31'),
  ('COV-3003', 'PAT-3003', 'PLAN-SHP-PPO', 'MEM-UAT-3003', '2026-01-01', '2026-12-31'),
  ('COV-3004', 'PAT-3004', 'PLAN-SHP-HMO', 'MEM-UAT-3004', '2026-01-01', '2026-12-31'),
  ('COV-3005', 'PAT-3005', 'PLAN-SHP-PPO', 'MEM-UAT-3005', '2026-01-01', '2026-12-31');

insert into public.clearway_policies (policy_id, payer_id, policy_name, procedure_family) values
  ('IMG-MRI-101', 'PAY-SHP-01', 'Advanced Imaging — Lumbar Spine MRI', 'Diagnostic imaging'),
  ('SURG-TKA-210', 'PAY-SHP-01', 'Total Knee Arthroplasty', 'Orthopedic surgery'),
  ('SURG-LSF-310', 'PAY-SHP-01', 'Lumbar Spinal Fusion', 'Spine surgery'),
  ('RX-ADL-410', 'PAY-SHP-01', 'Adalimumab Initial Therapy', 'Specialty medication'),
  ('DME-CPAP-510', 'PAY-SHP-01', 'Positive Airway Pressure Equipment', 'Durable medical equipment');

insert into public.clearway_policy_versions
  (policy_version_id, policy_id, version, effective_start, effective_end, content_hash, source_locator) values
  ('IMG-MRI-101:2026.1', 'IMG-MRI-101', '2026.1', '2026-01-01', '2026-12-31', 'sha256:uat-img-mri-101-2026-1', 'UAT policy library / IMG-MRI-101'),
  ('SURG-TKA-210:2026.1', 'SURG-TKA-210', '2026.1', '2026-01-01', '2026-12-31', 'sha256:uat-surg-tka-210-2026-1', 'UAT policy library / SURG-TKA-210'),
  ('SURG-LSF-310:2026.1', 'SURG-LSF-310', '2026.1', '2026-01-01', '2026-12-31', 'sha256:uat-surg-lsf-310-2026-1', 'UAT policy library / SURG-LSF-310'),
  ('RX-ADL-410:2026.1', 'RX-ADL-410', '2026.1', '2026-01-01', '2026-12-31', 'sha256:uat-rx-adl-410-2026-1', 'UAT policy library / RX-ADL-410'),
  ('DME-CPAP-510:2026.1', 'DME-CPAP-510', '2026.1', '2026-01-01', '2026-12-31', 'sha256:uat-dme-cpap-510-2026-1', 'UAT policy library / DME-CPAP-510');

insert into public.clearway_prior_auth_cases
  (case_id, patient_id, coverage_id, policy_version_id, case_type, scenario, request_date) values
  ('PA-3001', 'PAT-3001', 'COV-3001', 'IMG-MRI-101:2026.1', 'Diagnostic imaging', 'needs_documentation', '2026-07-21'),
  ('PA-3002', 'PAT-3002', 'COV-3002', 'SURG-TKA-210:2026.1', 'Orthopedic surgery', 'review_ready', '2026-07-21'),
  ('PA-3003', 'PAT-3003', 'COV-3003', 'SURG-LSF-310:2026.1', 'Spine surgery', 'conflicting_evidence', '2026-07-21'),
  ('PA-3004', 'PAT-3004', 'COV-3004', 'RX-ADL-410:2026.1', 'Specialty medication', 'needs_documentation', '2026-07-21'),
  ('PA-3005', 'PAT-3005', 'COV-3005', 'DME-CPAP-510:2026.1', 'Durable medical equipment', 'review_ready', '2026-07-21');

insert into public.clearway_orders
  (order_id, case_id, patient_id, procedure_name, procedure_code, code_system, ordered_date, service_date, ordering_clinician) values
  ('ORD-3001', 'PA-3001', 'PAT-3001', 'Lumbar spine MRI without contrast', '72148', 'CPT', '2026-07-18', '2026-07-29', 'Dr. Elena Brooks'),
  ('ORD-3002', 'PA-3002', 'PAT-3002', 'Total knee arthroplasty', '27447', 'CPT', '2026-07-16', '2026-08-12', 'Dr. Samuel Ortiz'),
  ('ORD-3003', 'PA-3003', 'PAT-3003', 'Lumbar spinal fusion', '22612', 'CPT', '2026-07-17', '2026-08-19', 'Dr. Priya Nair'),
  ('ORD-3004', 'PA-3004', 'PAT-3004', 'Adalimumab induction and maintenance', 'J0135', 'HCPCS', '2026-07-19', '2026-07-30', 'Dr. Marcus Hale'),
  ('ORD-3005', 'PA-3005', 'PAT-3005', 'CPAP device and supplies', 'E0601', 'HCPCS', '2026-07-15', '2026-07-28', 'Dr. Nina Shah');

insert into public.clearway_documents
  (document_id, case_id, patient_id, document_type, title, document_date, display_date, present, source_uri, content_hash) values
  ('DOC-3001-NOTE', 'PA-3001', 'PAT-3001', 'Clinical note', 'Spine clinic progress note', '2026-07-14', 'Jul 14, 2026', true, 'uat://PA-3001/DOC-3001-NOTE', 'sha256:uat-doc-3001-note'),
  ('DOC-3001-ORDER', 'PA-3001', 'PAT-3001', 'Order', 'Lumbar MRI order', '2026-07-18', 'Jul 18, 2026', true, 'uat://PA-3001/DOC-3001-ORDER', 'sha256:uat-doc-3001-order'),
  ('DOC-3001-PT', 'PA-3001', 'PAT-3001', 'Treatment record', 'Physical therapy treatment summary', null, 'Not received', false, null, null),

  ('DOC-3002-ORTHO', 'PA-3002', 'PAT-3002', 'Clinical note', 'Orthopedic surgery consultation', '2026-07-10', 'Jul 10, 2026', true, 'uat://PA-3002/DOC-3002-ORTHO', 'sha256:uat-doc-3002-ortho'),
  ('DOC-3002-XRAY', 'PA-3002', 'PAT-3002', 'Imaging report', 'Weight-bearing knee radiographs', '2026-07-08', 'Jul 8, 2026', true, 'uat://PA-3002/DOC-3002-XRAY', 'sha256:uat-doc-3002-xray'),
  ('DOC-3002-PT', 'PA-3002', 'PAT-3002', 'Treatment record', 'Conservative-treatment history', '2026-07-06', 'Jul 6, 2026', true, 'uat://PA-3002/DOC-3002-PT', 'sha256:uat-doc-3002-pt'),
  ('DOC-3002-CLEAR', 'PA-3002', 'PAT-3002', 'Preoperative clearance', 'Medical optimization clearance', '2026-07-15', 'Jul 15, 2026', true, 'uat://PA-3002/DOC-3002-CLEAR', 'sha256:uat-doc-3002-clear'),

  ('DOC-3003-SPINE', 'PA-3003', 'PAT-3003', 'Clinical note', 'Spine surgery consultation', '2026-07-11', 'Jul 11, 2026', true, 'uat://PA-3003/DOC-3003-SPINE', 'sha256:uat-doc-3003-spine'),
  ('DOC-3003-NEURO', 'PA-3003', 'PAT-3003', 'Clinical note', 'Neurologic examination', '2026-07-12', 'Jul 12, 2026', true, 'uat://PA-3003/DOC-3003-NEURO', 'sha256:uat-doc-3003-neuro'),
  ('DOC-3003-IMG', 'PA-3003', 'PAT-3003', 'Imaging report', 'Lumbar flexion-extension radiographs', '2026-07-09', 'Jul 9, 2026', true, 'uat://PA-3003/DOC-3003-IMG', 'sha256:uat-doc-3003-img'),
  ('DOC-3003-TX', 'PA-3003', 'PAT-3003', 'Treatment record', 'Nonoperative treatment history', '2026-07-07', 'Jul 7, 2026', true, 'uat://PA-3003/DOC-3003-TX', 'sha256:uat-doc-3003-tx'),

  ('DOC-3004-RHEUM', 'PA-3004', 'PAT-3004', 'Clinical note', 'Rheumatology treatment note', '2026-07-16', 'Jul 16, 2026', true, 'uat://PA-3004/DOC-3004-RHEUM', 'sha256:uat-doc-3004-rheum'),
  ('DOC-3004-LABS', 'PA-3004', 'PAT-3004', 'Laboratory report', 'Baseline CBC and liver panel', '2026-07-17', 'Jul 17, 2026', true, 'uat://PA-3004/DOC-3004-LABS', 'sha256:uat-doc-3004-labs'),
  ('DOC-3004-ORDER', 'PA-3004', 'PAT-3004', 'Order', 'Adalimumab order', '2026-07-19', 'Jul 19, 2026', true, 'uat://PA-3004/DOC-3004-ORDER', 'sha256:uat-doc-3004-order'),
  ('DOC-3004-TB', 'PA-3004', 'PAT-3004', 'Laboratory report', 'Tuberculosis screening result', null, 'Not received', false, null, null),

  ('DOC-3005-SLEEP', 'PA-3005', 'PAT-3005', 'Sleep study', 'Polysomnography report', '2026-07-09', 'Jul 9, 2026', true, 'uat://PA-3005/DOC-3005-SLEEP', 'sha256:uat-doc-3005-sleep'),
  ('DOC-3005-NOTE', 'PA-3005', 'PAT-3005', 'Clinical note', 'Sleep medicine consultation', '2026-07-12', 'Jul 12, 2026', true, 'uat://PA-3005/DOC-3005-NOTE', 'sha256:uat-doc-3005-note'),
  ('DOC-3005-ORDER', 'PA-3005', 'PAT-3005', 'Order', 'CPAP equipment order', '2026-07-15', 'Jul 15, 2026', true, 'uat://PA-3005/DOC-3005-ORDER', 'sha256:uat-doc-3005-order');

insert into public.clearway_policy_criteria
  (criterion_id, policy_version_id, criterion_code, title, description, policy_quote, policy_locator, ordinal, required) values
  ('IMG-MRI-101:C1', 'IMG-MRI-101:2026.1', 'C1', 'Symptoms documented for required duration', 'Symptoms must continue beyond the policy-defined period.', 'Symptoms persist for at least six weeks despite initial conservative management.', 'IMG-MRI-101 · page 3 · section 2.1', 1, true),
  ('IMG-MRI-101:C2', 'IMG-MRI-101:2026.1', 'C2', 'Conservative treatment documented', 'Treatment course, dates, and response must be included.', 'The record must document at least six weeks of provider-directed conservative treatment and response.', 'IMG-MRI-101 · page 4 · section 2.2', 2, true),
  ('IMG-MRI-101:C3', 'IMG-MRI-101:2026.1', 'C3', 'MRI order and indication are consistent', 'The requested study must match the documented indication.', 'The order must identify the requested MRI study and the documented clinical indication.', 'IMG-MRI-101 · page 2 · section 1.3', 3, true),
  ('IMG-MRI-101:C4', 'IMG-MRI-101:2026.1', 'C4', 'Red-flag exception', 'Urgent red-flag criteria are evaluated separately.', 'Red-flag findings may bypass conservative-treatment duration requirements.', 'IMG-MRI-101 · page 2 · section 1.4', 4, false),

  ('SURG-TKA-210:C1', 'SURG-TKA-210:2026.1', 'C1', 'Advanced knee osteoarthritis documented', 'Diagnosis and severity must be supported.', 'The record must show advanced symptomatic osteoarthritis of the operative knee.', 'SURG-TKA-210 · page 3 · section 2.1', 1, true),
  ('SURG-TKA-210:C2', 'SURG-TKA-210:2026.1', 'C2', 'Imaging supports structural disease', 'Recent weight-bearing imaging must support the diagnosis.', 'Weight-bearing radiographs must demonstrate advanced joint-space loss or equivalent disease.', 'SURG-TKA-210 · page 3 · section 2.2', 2, true),
  ('SURG-TKA-210:C3', 'SURG-TKA-210:2026.1', 'C3', 'Conservative therapy completed', 'Nonoperative therapies and response must be documented.', 'A clinically appropriate trial of nonoperative management must be documented.', 'SURG-TKA-210 · page 4 · section 2.3', 3, true),
  ('SURG-TKA-210:C4', 'SURG-TKA-210:2026.1', 'C4', 'Preoperative optimization completed', 'Medical readiness must be documented.', 'The record must include medical optimization and surgical risk review.', 'SURG-TKA-210 · page 5 · section 3.1', 4, true),

  ('SURG-LSF-310:C1', 'SURG-LSF-310:2026.1', 'C1', 'Structural instability documented', 'Imaging must support the requested fusion indication.', 'Imaging must demonstrate instability or another covered structural indication.', 'SURG-LSF-310 · page 3 · section 2.1', 1, true),
  ('SURG-LSF-310:C2', 'SURG-LSF-310:2026.1', 'C2', 'Nonoperative treatment completed', 'The treatment duration and response must be documented.', 'At least six months of clinically appropriate nonoperative treatment must be documented unless an exception applies.', 'SURG-LSF-310 · page 4 · section 2.2', 2, true),
  ('SURG-LSF-310:C3', 'SURG-LSF-310:2026.1', 'C3', 'Neurologic findings are consistent', 'Objective findings should be internally consistent.', 'Objective neurologic findings used to support surgery must be consistent across the submitted record.', 'SURG-LSF-310 · page 4 · section 2.3', 3, true),
  ('SURG-LSF-310:C4', 'SURG-LSF-310:2026.1', 'C4', 'Requested levels match the operative plan', 'The order and operative plan must identify the same levels.', 'The requested fusion levels must be consistent across the order and surgical plan.', 'SURG-LSF-310 · page 5 · section 3.1', 4, true),

  ('RX-ADL-410:C1', 'RX-ADL-410:2026.1', 'C1', 'Covered diagnosis documented', 'The diagnosis must match a covered indication.', 'Moderate-to-severe rheumatoid arthritis is a covered indication when documented by the treating specialist.', 'RX-ADL-410 · page 2 · section 1.2', 1, true),
  ('RX-ADL-410:C2', 'RX-ADL-410:2026.1', 'C2', 'Prior therapy documented', 'Prior conventional therapy and response must be documented.', 'The record must document an adequate trial and response to covered conventional therapy unless contraindicated.', 'RX-ADL-410 · page 3 · section 2.1', 2, true),
  ('RX-ADL-410:C3', 'RX-ADL-410:2026.1', 'C3', 'Baseline safety laboratory results available', 'Required baseline laboratory monitoring must be available.', 'Baseline complete blood count and liver-function results must be reviewed before therapy.', 'RX-ADL-410 · page 4 · section 3.1', 3, true),
  ('RX-ADL-410:C4', 'RX-ADL-410:2026.1', 'C4', 'Tuberculosis screening documented', 'A current tuberculosis screening result is required.', 'A negative tuberculosis screening result must be documented before initiation.', 'RX-ADL-410 · page 4 · section 3.2', 4, true),

  ('DME-CPAP-510:C1', 'DME-CPAP-510:2026.1', 'C1', 'Qualifying sleep study documented', 'A valid sleep study must meet the coverage threshold.', 'A qualifying sleep study must document the apnea-hypopnea index or respiratory-disturbance index.', 'DME-CPAP-510 · page 2 · section 1.1', 1, true),
  ('DME-CPAP-510:C2', 'DME-CPAP-510:2026.1', 'C2', 'Clinical symptoms documented', 'Symptoms or covered comorbidities must be present.', 'The clinical record must document qualifying symptoms or covered comorbid conditions.', 'DME-CPAP-510 · page 2 · section 1.2', 2, true),
  ('DME-CPAP-510:C3', 'DME-CPAP-510:2026.1', 'C3', 'Equipment order is complete', 'The order must identify device and settings.', 'A treating clinician order must identify the PAP device and prescribed settings.', 'DME-CPAP-510 · page 3 · section 2.1', 3, true),
  ('DME-CPAP-510:C4', 'DME-CPAP-510:2026.1', 'C4', 'Continued-use compliance', 'Compliance is evaluated for continued coverage.', 'Objective adherence is required for continued coverage after the initial trial.', 'DME-CPAP-510 · page 4 · section 3.1', 4, false);

insert into public.clearway_review_runs
  (run_id, case_id, trace_id, workflow_state, state_label, state_message, result_source, created_at) values
  ('RUN-UAT-3001-A', 'PA-3001', 'TRC-UAT-3001-A', 'more_information_required', 'Documentation required', 'The duration and order are supported, but provider-directed treatment dates and response are not documented.', 'precomputed_uat', '2026-07-23T12:00:01Z'),
  ('RUN-UAT-3002-A', 'PA-3002', 'TRC-UAT-3002-A', 'review_ready', 'Ready for clinician review', 'All required evidence categories are present and source-linked. A clinician must verify the package before submission.', 'precomputed_uat', '2026-07-23T12:00:02Z'),
  ('RUN-UAT-3003-A', 'PA-3003', 'TRC-UAT-3003-A', 'clinical_review_required', 'Clinical clarification required', 'Two clinical records disagree about the right ankle dorsiflexion finding. Both sources are preserved and automatic progression is stopped.', 'precomputed_uat', '2026-07-23T12:00:03Z'),
  ('RUN-UAT-3004-A', 'PA-3004', 'TRC-UAT-3004-A', 'more_information_required', 'Safety documentation required', 'Diagnosis, prior therapy, and baseline labs are supported. A current tuberculosis screening result is missing.', 'precomputed_uat', '2026-07-23T12:00:04Z'),
  ('RUN-UAT-3005-A', 'PA-3005', 'TRC-UAT-3005-A', 'review_ready', 'Ready for clinician review', 'The sleep study, symptoms, and equipment order are present and source-linked. A clinician must verify the package before submission.', 'precomputed_uat', '2026-07-23T12:00:05Z');

insert into public.clearway_criterion_results
  (run_id, criterion_id, status, clinical_sources, next_action, why_flagged) values
  ('RUN-UAT-3001-A', 'IMG-MRI-101:C1', 'supported', $json$[{"label":"Spine clinic progress note","quote":"Low-back pain with right-sided radicular symptoms has persisted for approximately eight weeks.","locator":"DOC-3001-NOTE · paragraph 4"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3001-A', 'IMG-MRI-101:C2', 'not_evidenced', $json$[{"label":"Spine clinic progress note","quote":"Patient reports home exercises and nonprescription anti-inflammatory medication.","locator":"DOC-3001-NOTE · paragraph 7"}]$json$::jsonb, 'Provide provider-directed treatment dates, modality, and documented response.', null),
  ('RUN-UAT-3001-A', 'IMG-MRI-101:C3', 'supported', $json$[{"label":"Lumbar MRI order","quote":"Lumbar spine MRI without contrast for persistent right lumbar radiculopathy.","locator":"DOC-3001-ORDER · order detail"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3001-A', 'IMG-MRI-101:C4', 'not_applicable', $json$[{"label":"Spine clinic progress note","quote":"No bowel or bladder change, saddle anesthesia, fever, trauma, or progressive motor loss.","locator":"DOC-3001-NOTE · paragraph 10"}]$json$::jsonb, 'No red-flag exception is being used for this request.', null),

  ('RUN-UAT-3002-A', 'SURG-TKA-210:C1', 'supported', $json$[{"label":"Orthopedic surgery consultation","quote":"Severe right-knee osteoarthritis with daily pain and functional limitation.","locator":"DOC-3002-ORTHO · assessment"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3002-A', 'SURG-TKA-210:C2', 'supported', $json$[{"label":"Weight-bearing knee radiographs","quote":"Near-complete medial-compartment joint-space loss with osteophyte formation.","locator":"DOC-3002-XRAY · impression"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3002-A', 'SURG-TKA-210:C3', 'supported', $json$[{"label":"Conservative-treatment history","quote":"Physical therapy, activity modification, NSAID therapy, and two injections provided inadequate durable relief.","locator":"DOC-3002-PT · summary"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3002-A', 'SURG-TKA-210:C4', 'supported', $json$[{"label":"Medical optimization clearance","quote":"Patient is medically optimized for planned right total knee arthroplasty.","locator":"DOC-3002-CLEAR · conclusion"}]$json$::jsonb, 'No additional information identified for this requirement.', null),

  ('RUN-UAT-3003-A', 'SURG-LSF-310:C1', 'supported', $json$[{"label":"Lumbar flexion-extension radiographs","quote":"Dynamic L4-L5 translation is consistent with segmental instability.","locator":"DOC-3003-IMG · impression"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3003-A', 'SURG-LSF-310:C2', 'supported', $json$[{"label":"Nonoperative treatment history","quote":"Seven months of physical therapy, medication management, and two injections produced persistent functional limitation.","locator":"DOC-3003-TX · summary"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3003-A', 'SURG-LSF-310:C3', 'conflicting', $json$[{"label":"Spine surgery consultation","quote":"Right ankle dorsiflexion is 4/5.","locator":"DOC-3003-SPINE · neurologic exam"},{"label":"Neurologic examination","quote":"Bilateral ankle dorsiflexion is 5/5 without focal weakness.","locator":"DOC-3003-NEURO · motor findings"}]$json$::jsonb, 'Obtain signed clinician clarification of the motor finding before progression.', 'The submitted records disagree about right ankle dorsiflexion strength.'),
  ('RUN-UAT-3003-A', 'SURG-LSF-310:C4', 'supported', $json$[{"label":"Spine surgery consultation","quote":"Planned posterolateral fusion at L4-L5.","locator":"DOC-3003-SPINE · operative plan"}]$json$::jsonb, 'No additional information identified for this requirement.', null),

  ('RUN-UAT-3004-A', 'RX-ADL-410:C1', 'supported', $json$[{"label":"Rheumatology treatment note","quote":"Seropositive rheumatoid arthritis remains moderately active.","locator":"DOC-3004-RHEUM · assessment"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3004-A', 'RX-ADL-410:C2', 'supported', $json$[{"label":"Rheumatology treatment note","quote":"Methotrexate was used for four months at a therapeutic dose with inadequate response.","locator":"DOC-3004-RHEUM · treatment history"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3004-A', 'RX-ADL-410:C3', 'supported', $json$[{"label":"Baseline CBC and liver panel","quote":"Blood counts and hepatic-function values are within the documented treatment parameters.","locator":"DOC-3004-LABS · result summary"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3004-A', 'RX-ADL-410:C4', 'not_evidenced', $json$[]$json$::jsonb, 'Provide a current tuberculosis screening result before therapy initiation.', null),

  ('RUN-UAT-3005-A', 'DME-CPAP-510:C1', 'supported', $json$[{"label":"Polysomnography report","quote":"Apnea-hypopnea index is 22 events per hour, consistent with moderate obstructive sleep apnea.","locator":"DOC-3005-SLEEP · interpretation"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3005-A', 'DME-CPAP-510:C2', 'supported', $json$[{"label":"Sleep medicine consultation","quote":"Patient reports excessive daytime sleepiness and witnessed apneas.","locator":"DOC-3005-NOTE · history"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3005-A', 'DME-CPAP-510:C3', 'supported', $json$[{"label":"CPAP equipment order","quote":"Auto-adjusting CPAP prescribed at 6–14 cm H2O with humidification and mask supplies.","locator":"DOC-3005-ORDER · order detail"}]$json$::jsonb, 'No additional information identified for this requirement.', null),
  ('RUN-UAT-3005-A', 'DME-CPAP-510:C4', 'not_applicable', $json$[]$json$::jsonb, 'Compliance applies to continued coverage after the initial trial.', null);

commit;
