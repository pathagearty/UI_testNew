# Clearway Synthetic Document Catalog

Status: populated in the temporary Supabase UAT database on 2026-07-23<br>
Scope: fully synthetic evidence-review inputs; no real patient, clinician, facility, payer, or policy data

## Purpose

This catalog defines the bounded document package for the five-case Clearway walkthrough. Each received document contains substantive plain text, stable IDs, synthetic authorship metadata, a signed timestamp, and a SHA-256 content hash. Each policy version contains full synthetic policy text and an independent SHA-256 hash.

The database view `clearway_ai_case_inputs` assembles the complete server-side model input while the browser-facing case view continues to return metadata and validated findings only.

## Case catalog

### PA-3001 — Lumbar spine MRI

Expected state: `more_information_required`

Received sources:

- `DOC-3001-NOTE` — signed spine-clinic note documenting eight weeks of symptoms, examination, self-directed care, and absence of red flags.
- `DOC-3001-ORDER` — signed lumbar MRI order with procedure code and indication.

Expected but not received:

- `DOC-3001-PT` — provider-directed physical-therapy treatment summary.

Pinned policy:

- `IMG-MRI-101:2026.1` — full synthetic lumbar-spine MRI evidence policy.

Intentional evidence logic:

- Symptom duration and the order are supported.
- Home exercises and nonprescription medication are present, but there is no dated provider-directed treatment course and response.
- The missing treatment record must remain `not_evidenced`; it must not be inferred from the home-exercise statement.

### PA-3002 — Total knee arthroplasty

Expected state: `review_ready`

Received sources:

- `DOC-3002-ORTHO` — orthopedic consultation with diagnosis, limitations, treatment history, examination, and plan.
- `DOC-3002-XRAY` — weight-bearing radiograph report describing advanced disease.
- `DOC-3002-PT` — twelve-week conservative-treatment summary and response.
- `DOC-3002-CLEAR` — signed medical-optimization review.

Pinned policy:

- `SURG-TKA-210:2026.1` — full synthetic total-knee-arthroplasty evidence policy.

Intentional evidence logic:

- All four required criteria have exact source-linked support.
- `review_ready` means ready for authorized clinician review, not approved or submitted.

### PA-3003 — Lumbar spinal fusion

Expected state: `clinical_review_required`

Received sources:

- `DOC-3003-SPINE` — spine-surgery consultation recording right ankle dorsiflexion as 4/5.
- `DOC-3003-NEURO` — independent neurologic examination recording bilateral ankle dorsiflexion as 5/5 without focal weakness.
- `DOC-3003-IMG` — flexion-extension imaging report documenting L4-L5 instability.
- `DOC-3003-TX` — seven-month nonoperative-treatment summary.

Pinned policy:

- `SURG-LSF-310:2026.1` — full synthetic lumbar-fusion evidence policy.

Intentional evidence logic:

- Instability, treatment history, and requested level are supported.
- The two signed neurologic findings directly conflict.
- The workflow must show both statements and request clinician clarification; it must never decide which source is correct.

### PA-3004 — Adalimumab specialty medication

Expected state: `more_information_required`

Received sources:

- `DOC-3004-RHEUM` — rheumatology note documenting active rheumatoid arthritis and inadequate methotrexate response.
- `DOC-3004-LABS` — synthetic baseline CBC and hepatic panel.
- `DOC-3004-ORDER` — medication order that explicitly conditions initiation on completed safety screening.

Expected but not received:

- `DOC-3004-TB` — current tuberculosis-screening result.

Pinned policy:

- `RX-ADL-410:2026.1` — full synthetic adalimumab initial-therapy evidence policy.

Intentional evidence logic:

- Diagnosis, prior therapy, and baseline laboratory criteria are supported.
- “Ordered” or “pending” is not a negative tuberculosis result.
- The missing result must remain `not_evidenced`, and the system must not infer a safety conclusion.

### PA-3005 — CPAP/DME

Expected state: `review_ready`

Received sources:

- `DOC-3005-SLEEP` — synthetic attended-polysomnography report with AHI 22 events/hour.
- `DOC-3005-NOTE` — sleep-medicine consultation documenting symptoms and study review.
- `DOC-3005-ORDER` — complete auto-adjusting CPAP and supplies order.

Pinned policy:

- `DME-CPAP-510:2026.1` — full synthetic initial PAP equipment policy.

Intentional evidence logic:

- Qualifying study, symptoms, and equipment order are supported.
- Continued-use adherence is explicitly `not_applicable` for the initial request and must not be treated as missing.

## Deterministic content gates

The migration fails if any of these conditions are violated:

1. Fewer or more than sixteen received source documents exist.
2. A received source lacks at least 250 characters of text or a SHA-256 hash.
3. Either intentionally missing document contains text.
4. A displayed clinical evidence quote is not present verbatim in its cited source.
5. A criterion's policy quote is not present verbatim in the pinned full policy.
6. The database does not produce exactly five AI input bundles.

The local backend additionally validates for every review:

- input schema and synthetic-data marker;
- selected case and order identity;
- exact policy quotes;
- document-manifest membership;
- document text length and SHA-256 hashes;
- exclusion of full text from the browser response.

## AI integration contract

Foundry should receive the payload from `clearway_ai_case_inputs` only after backend authorization and case/order validation. Expected model output should classify each supplied criterion using the bounded status vocabulary and return source document IDs, exact quotes, and locators.

Trusted backend code must then validate the output, derive workflow state, and persist the run. The model must not approve or deny authorization, manufacture missing evidence, resolve clinical conflicts, or perform payer submission.
