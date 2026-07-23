# Clearway — provider prior-authorization readiness workspace

Production-shaped UAT interface, Supabase-backed synthetic case service, enterprise-assurance one-pager, cross-functional implementation walkthrough, and interactive reference architecture for a provider-side Microsoft Foundry prior-authorization PoC. The primary UI helps a clinician select a linked patient/case/order context, review supplied records against the backend-resolved payer policy, identify missing or conflicting evidence, and prepare the package for clinician review.

Confirmed assumptions: the PoC uses synthetic cases, documents, policies, and expected results only; an Azure subscription is already available with team privileges. The implementation therefore verifies resource/project access and separates runtime identity rather than provisioning a new subscription or requesting broad ownership.

## What is included

- `index.html` — production-shaped provider workspace with linked patient/case/order selectors, backend-resolved policy context, and five synthetic Supabase UAT cases spanning ready, missing-evidence, and conflicting-evidence states.
- `enterprise-assurance-one-pager.html` — executive single-scroll enterprise-control blueprint covering the runtime architecture, layered guardrails, Foundry-native versus custom responsibilities, release gates, evaluation deck, and ten-day conversion path.
- `foundry-enterprise-harness-walkthrough.html` — detailed interactive cross-functional checklist with Foundry-specific portal/SDK steps, application-owned controls, verification gates, evidence requirements, troubleshooting, progress saving, search, and print support.
- `foundry-prior-auth-reference-architecture.html` — interactive line-and-box architecture showing the existing subscription boundary, reviewer/application/Foundry/data/observability layers, numbered request flow, ownership model, synthetic examples, and fail-closed scenarios.
- `FOUNDRY_ENTERPRISE_HARNESS_WALKTHROUGH.md` — source/reference version of the detailed walkthrough.
- `build_walkthrough.py` — dependency-free builder that converts the Markdown source into the interactive HTML artifact.
- `walkthrough.js` — local checklist progress, search, print, and reset behavior.
- `provider-ui.css` — responsive styling for the simple provider workspace.
- `styles.css` — shared styling retained for the technical walkthrough and assurance artifacts.
- `config.js` — deployment-safe backend URL and fallback settings; never contains secrets.
- `demo-data.js` — retained emergency fixtures; fixture fallback is disabled in the current Supabase configuration.
- `api-client.js` — API adapter for the local backend service.
- `app.js` — cascading clinical-context selection, evidence review, visual summaries, and human-review interactions.
- `server.py` — dependency-free local backend and static server; it proxies opaque case/order requests to Supabase PostgREST.
- `supabase/migrations/`, `supabase/seed.sql`, and `supabase/full_documents_seed.sql` — relational UAT schema, read-only synthetic-data policies, five-case seed dataset, sixteen received source texts, two intentionally absent records, five complete synthetic policy texts, and server-side API views.
- `BACKEND_INTEGRATION.md` — current Supabase UAT implementation, future Azure data recommendation, endpoint contract, validation requirements, and Shorya handoff.
- `SUPABASE_UAT_SETUP.md` — secret-safe setup, schema, seed catalog, health check, and AI-integration seam.
- `SYNTHETIC_DOCUMENT_CATALOG.md` — case-by-case source inventory, intentional evidence logic, deterministic content gates, and model-input contract.
- `PROVIDER_UI_UPDATE_NOTES.md` — focused case/policy identity flow, conflict handling, UI behavior, and demo-versus-production guidance.

## Run locally

```bash
git clone https://github.com/pathagearty/UI_test.git
cd UI_test
cp .env.example .env.local
# Add the temporary Supabase UAT values to .env.local, then:
chmod 600 .env.local
python3 server.py
```

Open:

- Provider workspace: <http://127.0.0.1:8788/index.html>
- Detailed implementation walkthrough: <http://127.0.0.1:8788/foundry-enterprise-harness-walkthrough.html>
- Interactive reference architecture: <http://127.0.0.1:8788/foundry-prior-auth-reference-architecture.html>
- Executive one-pager: <http://127.0.0.1:8788/enterprise-assurance-one-pager.html>

The local server uses only the Python standard library. A configured synthetic Supabase UAT project is required for the primary provider workspace. The technical walkthrough and assurance pages remain static.

## Important boundaries

- The current UAT artifact uses fully synthetic patients, clinicians, facilities, clinical-document text, payer-policy text, a fictional reviewer, and deterministic precomputed review results stored in a temporary Supabase project.
- Sixteen received documents and five policies contain substantive text and SHA-256 hashes. Two expected records intentionally remain absent to test missing-information detection.
- The current evidence review endpoint retrieves stored UAT results; it does not invoke an AI model. Conflict clarification is an explicitly ephemeral UAT interaction until a controlled write service is implemented.
- It is not connected to a live Foundry agent or any payer, EHR, clinical, or production system.
- Any implementation should be treated as unverified until the repository, endpoint, configuration, traces, and tests are inspected directly.
- The UI does not approve or deny prior authorization. It demonstrates a provider-side evidence-readiness workflow with human-owned next actions.
- The browser sends only opaque case/order identifiers. Entity authorization, relationship validation, effective policy resolution, evidence validation, and workflow-state derivation must occur in a trusted backend.
- This is Hexaware-inspired internal collateral, not an approved brand, security, clinical, legal, regulatory, or compliance architecture.
- No generative system can guarantee zero hallucinations. The design goal is to prevent unsupported content from becoming an action, detect residual errors, fail closed, and make human accountability explicit.

## Recommended integration boundary

Do **not** put Foundry credentials or direct model calls in the browser.

```text
Reviewer UI
  -> authenticated application backend
  -> deterministic intake + policy resolver
  -> bounded Microsoft Foundry model/agent step
  -> schema + citation + quote + prohibited-action validators
  -> code-derived workflow state
  -> human review / attestation
  -> audit store + OpenTelemetry/Application Insights + evaluation pipeline
```

### Minimal endpoint contract

`POST /api/v1/evidence-reviews`

Request:

```json
{
  "case_id": "PA-3001",
  "source_order_id": "ORD-3001"
}
```

The browser sends only the opaque case and order IDs. The authenticated backend authorizes the request and resolves the patient reference, procedure, payer/plan, request date, approved clinical documents, and exact effective policy version from trusted stores before invoking Foundry.

Response:

```json
{
  "run_id": "run_...",
  "trace_id": "trc_...",
  "workflow_state": "more_information_required",
  "workflow_state_source": "deterministic_router_v1",
  "policy": {"policy_id": "RAD-201", "version": "2026.1", "content_hash": "sha256:..."},
  "criteria": [
    {
      "criterion_id": "C2",
      "status": "not_evidenced",
      "policy_source": {"document_id": "RAD-201", "locator": "p.4 §2.2", "quote": "..."},
      "clinical_sources": [{"document_id": "NOTE-1042", "locator": "paragraph 7", "quote": "..."}],
      "missing_information": ["Provider-directed treatment dates and response"]
    }
  ],
  "guardrails": [{"control_id": "citation_resolution", "outcome": "pass"}],
  "human_action_required": true
}
```

### Allowed criterion states

- `supported`
- `not_evidenced`
- `conflicting`
- `unable_to_assess`
- `not_applicable`

The model must not emit `approved`, `denied`, `meets_medical_necessity`, or equivalent autonomous disposition fields. Workflow state is derived in code from validated criterion states and configured policy requirements.

## Required backend gates

1. **Intake:** schema, content type, file size, procedure allowlist, date and required-field checks.
2. **Policy authority:** exact policy/version/effective-date resolution and content hash.
3. **Isolation:** fresh case state; no prior-case conversational memory.
4. **Attack handling:** user-prompt and document/indirect-injection controls; retrieved content remains untrusted data.
5. **Output contract:** known criterion IDs, allowed statuses, no additional fields, bounded length.
6. **Provenance:** every material policy and clinical assertion has a source ID, locator, and exact resolvable quote.
7. **Prohibited actions:** no approve/deny, submission, EHR write, or payer action.
8. **Failure routing:** retry a transient/format failure once; otherwise stop and route to manual review.
9. **Drafting:** letters use only verified claim IDs and require clinician review/attestation.
10. **Audit:** one run/trace ID ties versions, spans, validator outcomes, evaluator results, and human action together.

## Foundry implementation decision

Current Microsoft documentation creates an important fork:

- Prompt-agent tracing is documented as generally available for prompt and hosted agents.
- Foundry agent guardrails are documented as preview, and Groundedness/Spotlighting controls are not currently applicable to agents.
- Structured Outputs are currently documented as unsupported with Foundry Agents Service.

Therefore:

### Option A — preserve the current prompt-agent demonstration

Use a trusted backend, prompt for the bounded JSON contract, strictly parse and validate the response, verify citations/quotes, retry once on a format-only failure, and fail closed. This minimizes near-term rework and is appropriate for the next integrated vertical slice.

### Option B — enterprise-bound structured mapping step

Use a direct Foundry Responses API model call that supports strict Structured Outputs for the policy-to-evidence mapping step, with explicit retrieval/functions and custom OpenTelemetry. Keep agent behavior only where tools or orchestration add demonstrated value.

Do not introduce a multi-agent framework before the endpoint-backed vertical slice, deterministic contract, trace, and evaluation deck are stable.

## Evaluation contract

### Deterministic release invariants — 100% required

- valid response schema;
- exact policy/version pinned;
- only known criteria and allowed statuses;
- every citation ID and locator resolves;
- every quoted string matches source text;
- zero fabricated material facts in the reviewer view or draft;
- zero approve/deny output or tool action;
- zero cross-case leakage;
- all invalid/stale/unsupported inputs fail closed;
- all runs correlate to trace and artifact versions.

### Domain-quality metrics — thresholds set with the workflow owner

- evidence-status accuracy;
- missing-evidence recall;
- contradiction-detection/escalation rate;
- unsupported-claim rate;
- draft factuality and citation completeness;
- reviewer agreement and override reasons;
- task adherence;
- p50/p95 latency and cost per case.

### Minimum test deck

At least 15 independent synthetic cases spanning:

- complete happy paths;
- missing treatment evidence;
- conflicting clinical notes;
- ambiguous or non-assessable evidence;
- stale/wrong policy versions;
- unsupported procedures;
- malformed/duplicate/oversize files;
- direct prompt injection;
- indirect instructions embedded in supplied/retrieved documents;
- sensitive-data leakage and prohibited-action attempts;
- noisy/scanned document edge cases;
- one or more cases not used during prompt development.

Foundry evaluators and red-team tooling add diagnostic signal. They do not replace deterministic assertions, independent workflow labels, or human review. Microsoft documents red-team results as potentially non-deterministic and subject to false positives; review them before mitigation decisions.

## Authoritative sources reviewed 2026-07-21

- [Agent tracing in Microsoft Foundry](https://learn.microsoft.com/en-us/azure/foundry/observability/concepts/trace-agent-concept)
- [Evaluate agents](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/evaluate-agent)
- [Guardrails and controls overview](https://learn.microsoft.com/en-us/azure/foundry/guardrails/guardrails-overview)
- [Structured Outputs](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/structured-outputs)
- [Prompt Shields](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/jailbreak-detection)
- [Groundedness detection](https://learn.microsoft.com/en-us/azure/ai-services/content-safety/concepts/groundedness)
- [AI Red Teaming Agent](https://learn.microsoft.com/en-us/azure/foundry/concepts/ai-red-teaming-agent)
- [Configure a private link](https://learn.microsoft.com/en-us/azure/foundry/how-to/configure-private-link)
- [Public Hexaware website](https://hexaware.com/)
