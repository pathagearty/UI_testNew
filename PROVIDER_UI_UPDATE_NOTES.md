# Provider UI Update Notes

Status: Production-shaped UAT UI, local backend, and temporary Supabase synthetic database connected; Foundry and production Azure integration remain pending<br>
Scope: Synthetic provider-side prior-authorization preparation workflow with cascading patient/case/order selection and backend-resolved policy authority

## 1. Add a dedicated conflicting-evidence case

Do not combine missing documentation and conflicting evidence in the same primary demo case.

Implemented synthetic cases:

1. MRI imaging with missing conservative-treatment documentation.
2. Knee-replacement surgery ready for clinician review.
3. Lumbar-fusion surgery with conflicting neurologic findings.
4. Specialty medication with missing tuberculosis screening.
5. CPAP/DME ready for clinician review.

### Conflict example

Policy criterion: An objective neurologic deficit may support the MRI request.

- Source A: “Reduced right ankle reflex.”
- Source B: “Lower-extremity reflexes are symmetric.”

Expected result:

- Criterion status: `conflicting`.
- Workflow state: `clinical_review_required`.
- Display both statements, source document IDs, dates, and locations.
- Explain: “These records disagree about the same clinical finding.”
- Primary action: **Request clinician clarification**.
- Do not allow the model to decide which statement is correct.

### Conflict-resolution demo

1. Run the case and show both conflicting sources.
2. Select **Request clinician clarification**.
3. Add a synthetic signed clarification or amended note.
4. Run the case again.
5. Update the criterion to `supported`, `not_evidenced`, or keep it `conflicting` based on the amended evidence.
6. Only allow clinician-review handoff after the conflict is resolved or explicitly accepted by an authorized clinician.

## 2. Case, patient, and policy selection

### Demo workflow

A dropdown is appropriate for a small synthetic demo:

1. Clinician selects a synthetic patient or case.
2. The browser sends only the trusted `case_id` to the backend.
3. The backend loads the patient, procedure, payer, coverage, documents, and request date from a case registry.
4. The backend resolves and pins the policy version.
5. The UI displays the populated information as read-only context.
6. The clinician starts the Foundry evidence review.

For the demo, the case and policy registries can be JSON/configuration files or a small database.

### Production-shaped workflow

Preferred production workflow:

1. Launch from the EHR with authenticated user and patient context, or use an authorized patient search.
2. Select an active order, service request, or prior-authorization case for that patient.
3. Create or retrieve the application-managed `case_id`.
4. Load approved case documents through the backend.
5. Resolve the applicable policy from payer/plan, procedure, request or service date, and other required routing metadata.
6. Pin the policy ID, version, effective dates, and content hash to the case.

A generic patient dropdown is suitable for the synthetic demo but not for a large production population. Production should use EHR launch/context or permission-controlled patient search to reduce selection errors and unnecessary PHI exposure.

### Recommended identifiers

- `patient_id`: trusted EHR/FHIR or synthetic patient identifier.
- `case_id`: application-managed prior-authorization case identifier.
- `source_order_id`: originating order or service-request identifier.
- `payer_id`, `plan_id`, and `coverage_id`: coverage-routing identifiers.
- `procedure_code`: requested service/procedure.
- `policy_id` and `policy_version`: resolved policy authority.
- `policy_hash`: immutable hash of the exact policy content used.
- `document_id`: approved source-document identifier.
- `run_id` and `trace_id`: Foundry/backend execution identifiers.

## 3. Backend verification

The model must not select or change the patient, case, or policy.

Before the Foundry call, the backend should:

1. Verify the authenticated user can access the selected case.
2. Load the case by `case_id`; do not trust patient or policy labels supplied by the browser.
3. Confirm every document belongs to the expected patient and case.
4. Confirm payer/plan, procedure code, and request date are present.
5. Resolve exactly one policy version that was effective for the request date.
6. Pin the policy ID, version, effective dates, and content hash to the run.
7. Stop if an identifier mismatches, the policy is stale, or policy resolution is ambiguous.

After the Foundry call, the backend should:

1. Confirm returned case, patient, policy, and criterion IDs match the pinned request.
2. Confirm cited document and policy-chunk IDs were supplied to the model.
3. Confirm exact quoted text appears in the referenced source.
4. Reject unknown statuses, criteria, fields, or approval/denial language.
5. Derive the workflow state in code and route unresolved conflicts to a clinician.

## 4. UI changes

Keep the existing UI structure and add only the following high-value changes:

1. Add a separate **Conflicting evidence** synthetic case.
2. Show conflicting statements side by side with source, date, and location.
3. Add a one-line **Why this was flagged** explanation.
4. Use contextual primary actions:
   - Missing evidence → **Request documentation**.
   - Conflicting evidence → **Request clinician clarification**.
   - Ready → **Send to clinician review**.
   - Invalid policy → **Select current policy**.
5. Add a compact verification strip showing:
   - Patient/case verified.
   - Policy version pinned.
   - Sources validated.
   - Trace ID.
6. Show the conflict before-and-after rerun during the demo.
7. Disable submission-ready drafting and forward progression while a material conflict remains unresolved.
8. Continue displaying that all data is synthetic and that the demo does not submit to or decide for a payer.

## 5. Demo success condition

The demo should show that the system can:

1. Load a trusted case.
2. Resolve and pin the applicable policy.
3. Use Foundry to map evidence to policy criteria.
4. Detect and cite a meaningful conflict.
5. Prevent unsafe automatic progression.
6. Help a clinician resolve the conflict.
7. Re-run the case and update the workflow state with an auditable trace.
