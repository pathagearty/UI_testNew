# Clearway Backend Data Integration Contract

Status: temporary Supabase synthetic-UAT database and local API connected; Foundry and production Azure resources are not connected<br>
Updated: 2026-07-23<br>
Owner handoff: Shorya / backend, Foundry, and cloud implementation team

## 0. Current Supabase UAT implementation

The provider workspace is currently connected through:

```text
Browser UI
  -> local `server.py` on 127.0.0.1:8788
  -> Supabase PostgREST synthetic-only views
  -> Clearway-prefixed relational PostgreSQL tables
```

The browser sends only case and order IDs. Supabase configuration is loaded by
`server.py` from the git-ignored `.env.local`; no credential is included in
`index.html`, `config.js`, `app.js`, or `api-client.js`.

Database artifacts:

- `supabase/migrations/20260723173300_clearway_uat_schema.sql`
- `supabase/migrations/20260723175343_clearway_full_synthetic_document_text.sql`
- `supabase/seed.sql`
- `supabase/full_documents_seed.sql`
- `supabase/clearway_uat_schema.sql` and `supabase/clearway_uat_seed.sql` as readable source copies
- `SYNTHETIC_DOCUMENT_CATALOG.md` for the case-level source inventory and evidence invariants

The schema contains Clearway-prefixed patients, payers, plans, coverages,
policies and versions, cases, orders, documents, policy criteria, review runs,
criterion results, and clarifications. Anonymous/publishable-key access is
read-only and restricted by row-level security to records marked synthetic.
There is no anonymous insert, update, or delete policy.

The connected project also contains sixteen substantive received clinical/order/report texts, two intentionally absent expected records, and five complete synthetic policy texts. Received documents and policies have SHA-256 hashes. The `clearway_ai_case_inputs` view assembles each case's pinned policy, criteria, document manifest, and received source text for server-side model invocation; the browser-facing case view intentionally excludes those full bodies.

The five seeded case families are:

| Case | Type | Expected state |
|---|---|---|
| `PA-3001` | Lumbar MRI imaging | Missing conservative-treatment documentation |
| `PA-3002` | Total knee arthroplasty | Ready for clinician review |
| `PA-3003` | Lumbar spinal fusion | Conflicting neurologic findings |
| `PA-3004` | Adalimumab specialty medication | Missing tuberculosis screening |
| `PA-3005` | CPAP durable medical equipment | Ready for clinician review |

Current review results are deterministic UAT records stored in Supabase. The
evidence-review endpoint reloads and validates the complete server-side input bundle—including exact policy quotes, source membership, document lengths, and hashes—but does **not** yet invoke Foundry or another AI service.
The conflict-clarification transition is deliberately ephemeral in the local
server until authenticated, auditable database writes are implemented.

## 1. Workflow decision

The production-shaped workflow is:

1. An authenticated clinician selects a patient from the authorized UAT/work queue.
2. The UI shows only prior-authorization cases linked to that patient.
3. The clinician selects a case and an active order/service request.
4. The browser sends the opaque `case_id` and `source_order_id` to the backend.
5. The backend authorizes access and reloads the canonical linked entities.
6. The backend resolves payer, plan, coverage, procedure, request date, approved documents, and exactly one effective payer-policy version.
7. The backend pins the policy ID, version, effective dates, and content hash.
8. The backend invokes the bounded evidence-review service.
9. Validators check identifiers, schema, criterion statuses, citations, exact quotes, prohibited actions, and case isolation.
10. The UI renders the validated review and routes missing or conflicting evidence to a clinician.

The browser must not independently select or redefine payer-policy authority. This prevents a reviewer from combining a patient, order, coverage, or policy that does not belong to the selected case.

## 2. Current UI adapter

Files:

- `config.js` — deployment configuration; contains no secret.
- `demo-data.js` — retained emergency fixtures; disabled in the connected configuration.
- `api-client.js` — same-origin backend adapter.
- `app.js` — cascading selectors, review workflow, render logic, and human-review actions.
- `server.py` — local static server and Supabase proxy using the Python standard library; it validates full-text AI inputs without returning the source bodies to the browser.

The current local configuration uses the same origin:

```js
window.CLEARWAY_CONFIG = Object.freeze({
  apiBaseUrl: window.location.origin,
  dataSourceLabel: 'Supabase UAT service',
  requestTimeoutMs: 8000,
  allowUatFixtureFallback: false
});
```

Fallback remains disabled so a Supabase/backend failure cannot be mistaken for a successful database-backed run.

Do not put Supabase database credentials, service-role credentials, Azure credentials, Foundry keys, tokens, or client secrets in `config.js` or any browser asset. The Supabase publishable key is intentionally restricted to read-only synthetic rows, but it is still kept behind the local API so the browser contract remains cloud-neutral.

## 3. Browser-to-backend API

### Load the authorized work queue

`GET /api/v1/prior-authorizations/workspace`

Response:

```json
{
  "patients": [
    {
      "id": "PAT-3001",
      "name": "Morgan Lee",
      "mrn": "MRN-UAT-83001",
      "dateOfBirth": "1982-04-19"
    }
  ],
  "cases": [
    {
      "id": "PA-3001",
      "patientId": "PAT-3001",
      "orderIds": ["ORD-3001"],
      "procedure": "Lumbar spine MRI",
      "scenario": "needs_documentation",
      "statusLabel": "Needs documentation",
      "requestDate": "2026-07-21"
    }
  ]
}
```

The backend returns only records the authenticated user is authorized to view. A large production population should use EHR launch or permission-controlled search rather than returning an unrestricted patient list.

### Load one canonical case graph

`GET /api/v1/prior-authorization-cases/{case_id}`

The response shape matches the case objects in `demo-data.js`:

- `id`
- `requestDate`
- `patient`
- `orders[]`
- `selectedOrderId`
- `coverage.payer`
- `coverage.plan`
- `coverage.coverageId`
- `policy`
- `review`
- `documents[]`
- `criteria[]`

The backend—not the browser—must construct this graph from authorized canonical records.

### Run evidence review

`POST /api/v1/evidence-reviews`

Request:

```json
{
  "case_id": "PA-3001",
  "source_order_id": "ORD-3001"
}
```

The server must ignore browser-supplied display labels and reload the trusted patient, coverage, policy, documents, and procedure using the IDs.

Response: the same canonical case shape, with a new validated `review`, `criteria`, `runId`, and `traceId`. The current UAT response also includes a non-sensitive `review.inputBundle` summary (schema version, source count, character counts, criterion count, and validation flag), but not full policy or document text.

### Record a clinician clarification

`POST /api/v1/prior-authorization-cases/{case_id}/clarifications`

Request:

```json
{
  "criterion_id": "C3",
  "clarification_document_id": "DOC-UAT-CLAR-3003"
}
```

The actual document must already exist in an authorized clinical/document store. The backend validates its patient/case ownership and clinician signature before rerunning evidence review.

## 4. Recommended Azure data design

### Primary recommendation

Use **Azure SQL Database** for the authoritative relational case registry because patients, cases, orders, coverage, policy versions, documents, runs, and criterion results require referential integrity and auditable joins.

Use:

- **Azure SQL Database** — metadata, entity relationships, workflow state, review results, human actions, and immutable run references.
- **Azure Blob Storage** — source clinical documents and payer-policy source files.
- **Azure AI Search** — optional indexed policy/document chunks for retrieval; it is not the system of record.
- **Azure App Service or Azure Container Apps** — authenticated backend API.
- **Microsoft Entra ID and managed identity** — user authentication and service-to-service access.
- **Azure Key Vault** — secrets only when managed identity cannot eliminate them.
- **Application Insights / OpenTelemetry** — trace and audit correlation.

Cosmos DB is reasonable for denormalized review artifacts, but it should not be the default authoritative registry unless Shorya can explain the partitioning, consistency, and relationship-validation design. For this workflow, Azure SQL is the simpler and safer starting point.

### Minimum relational entities

| Entity | Key fields | Purpose |
|---|---|---|
| `patients` | `patient_id`, external/FHIR ID, MRN | Authorized patient identity reference |
| `prior_auth_cases` | `case_id`, `patient_id`, `coverage_id`, request date, state | Workflow root |
| `orders` | `source_order_id`, `case_id`, procedure code, service date | Requested service |
| `payers` | `payer_id` | Payer identity |
| `plans` | `plan_id`, `payer_id` | Plan identity |
| `coverages` | `coverage_id`, `patient_id`, `plan_id`, effective dates | Coverage routing |
| `policies` | `policy_id`, payer/plan/procedure mapping | Policy family |
| `policy_versions` | version, effective dates, content hash, source URI | Exact policy authority |
| `case_documents` | `document_id`, `case_id`, `patient_id`, Blob URI, hash | Approved source documents |
| `review_runs` | `run_id`, `case_id`, `policy_version_id`, `trace_id`, state | Auditable execution |
| `criterion_results` | `run_id`, criterion ID, allowed status, citations | Validated evidence mapping |
| `clarifications` | case, criterion, signed document, actor, timestamp | Human resolution path |

Use foreign keys and backend authorization checks. Database relationships do not replace user-level access controls.

## 5. Required backend validation

Before invoking Foundry:

1. Authorize the reviewer for the selected case.
2. Confirm the order belongs to the case and patient.
3. Confirm every document belongs to the same patient and case.
4. Confirm payer, plan, coverage, procedure code, and request date.
5. Resolve exactly one effective policy version.
6. Pin the policy hash and all source-document hashes.
7. Verify every criterion's policy quote against the pinned policy text and every received document hash against the supplied text.
8. Stop on missing, stale, mismatched, or ambiguous context.

After Foundry returns:

1. Enforce a deterministic JSON schema.
2. Permit only known criteria and allowed statuses.
3. Verify all case, patient, policy, order, and document IDs.
4. Resolve every citation and exact quote against supplied content.
5. Reject approval/denial, autonomous medical-necessity decisions, submission, or write-back actions.
6. Derive workflow state in backend code.
7. Correlate the response with `run_id` and `trace_id`.
8. Preserve human corrections and original evidence.

## 6. Required UAT scenarios

The local fixture service currently covers:

1. **Ready for clinician review** — all required evidence categories are source-linked.
2. **Needs documentation** — some criteria are supported but treatment dates/response are insufficient.
3. **Conflicting evidence** — two clinical sources disagree and progression is stopped.
4. **Policy validation required** — an expired policy blocks review.

The first three are the core demonstration. The fourth is a fail-closed technical assurance case.

## 7. Demo versus production boundary

Production-shaped now:

- linked clinical context selectors;
- read-only backend-resolved policy authority;
- production-style entity IDs;
- visual readiness and evidence summaries;
- source-linked criteria;
- full synthetic source and policy text assembled into a bounded server-side AI input contract;
- deterministic source-membership, quote, and content-hash validation before review;
- loading, blocking, missing-evidence, conflict, and ready states;
- API adapter and trace/run fields;
- human-owned progression.

Still UAT/demo only:

- all records are synthetic;
- fixture review results are deterministic local data;
- no live Azure database, EHR, payer, Foundry agent, or production identity path is connected;
- buttons do not submit to a payer or write to an EHR;
- the named reviewer is fictional;
- policy text and evaluation results are illustrative.

Do not remove this boundary from the handoff, testing evidence, or stakeholder narrative even though prototype-style banners have been removed from the primary interface.
