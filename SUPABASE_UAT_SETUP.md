# Clearway Supabase Synthetic-UAT Setup

Status: connected and verified on 2026-07-23<br>
Scope: temporary, fully synthetic prior-authorization walkthrough data

## Security boundary

- `.env.local` is ignored by Git and permissioned `600`.
- Database passwords and connection strings remain server-side only.
- Browser assets contain no Supabase URL, key, password, or database host.
- The browser calls the same-origin local API in `server.py`.
- The local API reads Supabase through PostgREST using the publishable key.
- Row-level security permits anonymous/publishable-key `SELECT` only for records marked synthetic.
- No anonymous insert, update, or delete policy exists.
- Do not reuse this design for real clinical or production data without authenticated identity, row-level authorization, audit controls, and a managed secret store.

## Local environment

Create `.env.local` from `.env.example` and set:

```text
SUPABASE_PROJECT_REF=<temporary-project-reference>
SUPABASE_DB_URL=<percent-encoded-direct-postgres-connection-string>
SUPABASE_URL=<project-api-url>
SUPABASE_PUBLISHABLE_KEY=<publishable-key>
NEXT_PUBLIC_SUPABASE_URL=<same-project-api-url>
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<same-publishable-key>
CLEARWAY_HOST=127.0.0.1
CLEARWAY_PORT=8788
```

The `NEXT_PUBLIC_*` names are retained only for compatibility with a possible future Next.js application. This repository does not load them into the browser.

## Database artifacts

- `supabase/migrations/20260723173300_clearway_uat_schema.sql`
- `supabase/migrations/20260723175343_clearway_full_synthetic_document_text.sql`
- `supabase/seed.sql`
- `supabase/full_documents_seed.sql`
- `supabase/clearway_uat_schema.sql`
- `supabase/clearway_uat_seed.sql`

The migration creates only `clearway_*` objects in the public schema.

Primary entities:

- patients;
- payers and plans;
- coverages;
- policies and versioned policy content;
- prior-authorization cases;
- orders;
- documents;
- policy criteria;
- review runs and criterion results;
- clarifications.

API views:

- `clearway_workspace_payload`;
- `clearway_case_payloads`;
- `clearway_ai_case_inputs` — server-side full policy/source-document bundle for the bounded review service.

Full-text content:

- sixteen received clinical/order/report documents with substantive text and SHA-256 hashes;
- two expected-but-not-received records with intentionally null text;
- five complete synthetic policy versions with exact criterion quotes and SHA-256 hashes;
- deterministic migration assertions that verify quote-to-source alignment, missing-document behavior, and five complete AI input bundles.

## Apply to a new temporary project

The Supabase CLI must already be installed. No account linking is required when a direct database URL is provided.

```bash
set -a
. ./.env.local
set +a
supabase db push \
  --db-url "$SUPABASE_DB_URL" \
  --include-all \
  --include-seed \
  --yes
```

Run the seed only against an empty Clearway schema. The deterministic IDs intentionally reject duplicate inserts.

## Run the connected UI

```bash
python3 server.py
```

Open <http://127.0.0.1:8788/index.html>.

Health check:

```bash
curl -fsS http://127.0.0.1:8788/api/health
```

Expected shape:

```json
{
  "status": "ok",
  "data_source": "supabase_uat",
  "patients": 5,
  "cases": 5,
  "ai_input_bundles": 5
}
```

## Seeded walkthrough cases

| Case | Service | Scenario | Expected workflow state |
|---|---|---|---|
| `PA-3001` | Lumbar spine MRI | Missing conservative-treatment dates and response | Documentation required |
| `PA-3002` | Total knee arthroplasty | Complete evidence package | Ready for clinician review |
| `PA-3003` | Lumbar spinal fusion | Conflicting right-ankle dorsiflexion findings | Clinical clarification required |
| `PA-3004` | Adalimumab specialty medication | Missing tuberculosis screening | Safety documentation required |
| `PA-3005` | CPAP device and supplies | Complete initial-coverage evidence | Ready for clinician review |

Distribution: two ready, two missing information, and one conflicting information.

## Current API contract

- `GET /api/health`
- `GET /api/v1/prior-authorizations/workspace`
- `GET /api/v1/prior-authorization-cases/{case_id}`
- `POST /api/v1/evidence-reviews`
- `POST /api/v1/prior-authorization-cases/{case_id}/clarifications`

`POST /api/v1/evidence-reviews` currently validates the case/order relationship, retrieves the full server-side AI input bundle, verifies the pinned policy quotes, document manifest, source text, and SHA-256 hashes, and then returns the deterministic review stored in Supabase. Full document and policy bodies are not returned to the browser. It does not yet call AI.

The clarification endpoint currently produces an ephemeral UAT transition in memory. It does not write to Supabase. Replace it with an authenticated, audited write path before persistence is needed.

## AI integration seam

The future bounded AI/review service should replace only the implementation behind `POST /api/v1/evidence-reviews`. It should:

1. authorize the reviewer and reload the canonical case graph;
2. resolve the effective policy version server-side;
3. load `clearway_ai_case_inputs` and retrieve only the supplied case's received documents and pinned policy;
4. return a deterministic, schema-validated criterion result;
5. preserve citations, quotes, document IDs, policy version, and trace ID;
6. derive workflow state in trusted code;
7. persist the run and findings to `clearway_review_runs` and `clearway_criterion_results`;
8. fail closed on missing identifiers, cross-case evidence, invalid citations, or unsupported actions.

The browser adapter should not need to change when this service is introduced.
