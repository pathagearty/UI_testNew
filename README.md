# Clearway — Microsoft Foundry prior-authorization evidence review

Clearway is a synthetic UAT workspace for demonstrating a production-shaped prior-authorization evidence review. The current runtime deliberately does **not** use Supabase or precomputed review fixtures.

## Current boundary

```text
Browser → trusted Python backend → local synthetic source bundle
        → Microsoft Foundry agent → backend schema/citation validators → UI
```

- The browser sends only `case_id` and `source_order_id`.
- The backend loads one bounded synthetic case/policy/document bundle.
- Microsoft Foundry performs the semantic evidence comparison.
- The backend validates all returned criteria, statuses, source IDs and exact quotes.
- The backend derives workflow state; the model cannot approve, deny or submit.
- The backend deterministically builds a concise submission brief and source-linked draft medical necessity letter from the validated result.
- The UI starts **not analyzed** and renders completed results only when `resultSource` is `microsoft_foundry_agent`.
- No runtime fixture fallback exists.

## Quick start without Foundry

This confirms the safe unanalyzed and fail-closed state:

```bash
python3 -m unittest -v test_clearway.py
python3 server.py
```

Open `http://127.0.0.1:4173`.

Expected behavior without work-laptop Foundry configuration:

- all five cases load from local synthetic source-only JSON;
- every case says **Awaiting Microsoft Foundry analysis**;
- criteria say **Not analyzed**;
- readiness metrics and downstream actions remain unavailable;
- running a review returns `503 foundry_not_configured`;
- no precomputed result is displayed.

## Work-laptop live setup

Use the firewall-approved work laptop and follow:

- [`WORK_LAPTOP_FOUNDRY_HANDOFF.md`](WORK_LAPTOP_FOUNDRY_HANDOFF.md)
- [`.env.example`](.env.example)

Minimum configuration:

```dotenv
CLEARWAY_FOUNDRY_AGENT_ENDPOINT=https://<account>.services.ai.azure.com/api/projects/<project>/agents/<agent>/endpoint/protocols/openai/responses
CLEARWAY_FOUNDRY_API_VERSION=v1
CLEARWAY_FOUNDRY_TOKEN_COMMAND=az account get-access-token --scope https://ai.azure.com/.default --query accessToken -o tsv
```

The endpoint and authentication remain server-side. Never commit `.env.foundry.local`, tokens or credentials.

## API

### Health

```http
GET /api/health
```

Reports the source repository, analysis service, Foundry configuration state and synthetic case count without exposing endpoint values.

### Workspace

```http
GET /api/v1/prior-authorizations/workspace
```

Returns the synthetic patient/case selector metadata only.

### Case

```http
GET /api/v1/prior-authorization-cases/{case_id}
```

Returns source context with `review.state = not_analyzed` and pending criteria. It never returns stored analysis.

### Live evidence review

```http
POST /api/v1/evidence-reviews
Content-Type: application/json

{
  "case_id": "PA-3001",
  "source_order_id": "ORD-3001"
}
```

The backend validates the input, invokes the configured Foundry agent, validates its structured output and returns a transient reviewed case with `submissionBrief`. The brief includes explainable readiness, supported requirements, actionable documentation gaps, review notes, next steps and a source-linked draft letter. Failed configuration, network calls, agent responses or citations stop closed.

## Synthetic cases

| Case | Designed control scenario |
|---|---|
| `PA-3001` | Missing documentation |
| `PA-3002` | Complete review-ready package |
| `PA-3003` | Conflicting source evidence |
| `PA-3004` | Missing monitoring evidence |
| `PA-3005` | Complete review-ready package |

These labels describe the source design. Only live work-laptop Foundry runs establish the actual agent results.

## Source files

| Path | Purpose |
|---|---|
| `data/workspace.json` | Synthetic work queue |
| `data/cases/*.json` | Display-safe source context; no completed analysis |
| `data/inputs/*.json` | Full bounded policy and source-document inputs |
| `server.py` | Source retrieval, validation, API and workflow derivation |
| `foundry_client.py` | Entra-authenticated Foundry stable-endpoint call |
| `submission_brief.py` | Deterministic submission brief and source-linked draft-letter view model |
| `test_clearway.py` | Boundary and citation regression tests |
| `app.js` | Unanalyzed/live/error states, submission brief and draft-letter rendering |
| `api-client.js` | Backend-only API client with no fixture fallback |

The older `demo-data.js`, Supabase SQL and Supabase environment artifacts are retained only for migration/history. They are not imported by `index.html` or `server.py`.

## Verification

```bash
python3 -m py_compile server.py foundry_client.py submission_brief.py test_clearway.py
node --check app.js
node --check api-client.js
node --check config.js
python3 -m unittest -v test_clearway.py
```

The regression suite verifies:

- five source-only cases;
- all cases initially unanalyzed;
- all full input bundles and hashes;
- fail-closed behavior without Foundry;
- exact-citation rejection;
- Foundry provenance mapping;
- complete and incomplete draft-letter safety states;
- current hosted-agent API-version query handling;
- blocked web access to source inputs, Python and environment files.

A live Foundry success cannot be verified from the personal laptop because the endpoint is firewall/IP restricted. That final gate must run on the approved work laptop.

## Safety boundary

- Synthetic data only.
- No EHR or payer write-back.
- No autonomous approval, denial, submission or medical-necessity decision.
- Clinician verification remains required.
- No unrestricted agent data access.
- No browser-side Foundry credentials.
- No silent fallback or replay presented as a live run.
