# Clearway work-laptop Foundry handoff

## Objective

Run the Clearway synthetic prior-authorization demonstration from the firewall-approved work laptop so that:

1. the browser selects one synthetic case;
2. the trusted backend loads and validates only that case's local policy and source documents;
3. the backend invokes the configured Microsoft Foundry agent through its stable Responses endpoint;
4. Foundry compares every fixed policy criterion with the supplied clinical evidence;
5. the backend rejects malformed results, invented citations, unavailable source IDs, policy drift, decision fields, and unsupported statuses;
6. the UI displays the result only after validation and labels it as Microsoft Foundry analysis.

Supabase is not used at runtime. No precomputed result or browser fixture fallback exists.

## Runtime architecture

```text
Browser
  | case_id + source_order_id only
  v
Clearway backend (server.py)
  |-- loads local synthetic source-only JSON
  |-- validates case/order/policy/date/document relationships and hashes
  |-- constructs one bounded Foundry request
  v
Microsoft Foundry agent stable Responses endpoint
  |-- maps fixed policy criteria to supplied source evidence
  |-- returns strict JSON only
  v
Clearway backend
  |-- validates schema, criterion coverage, enums, source IDs and exact quotes
  |-- derives workflow state in code
  v
Browser UI
  |-- displays Foundry provenance and source-linked findings
```

The backend—not the model—owns authorization, case retrieval, policy selection, input hashes, output validation and workflow state. Foundry owns the bounded semantic evidence comparison. This avoids giving the agent unrestricted database access while still making the live agent perform the actual review.

## Files that now matter

| File | Role |
|---|---|
| `server.py` | Trusted API, local source retrieval, input validation, output validation and workflow derivation |
| `foundry_client.py` | Microsoft Entra authentication and stable Foundry Responses-endpoint invocation |
| `data/workspace.json` | Selectable synthetic work queue; no analysis |
| `data/cases/*.json` | Display-safe source context; every case starts `not_analyzed` |
| `data/inputs/*.json` | Bounded full policy/document inputs sent server-side to Foundry |
| `api-client.js` | Backend-only browser client; no fixture fallback |
| `app.js` | Unanalyzed/loading/error/validated-Foundry UI states |
| `.env.example` | Non-secret configuration template |
| `test_clearway.py` | Fail-closed, input-integrity and citation-validation regression tests |

`demo-data.js`, the Supabase SQL files and the old Supabase environment values are retained only as historical/migration artifacts; the current page and server do not import or query them.

## Work-laptop setup

### 1. Transfer the repository

Use the approved internal Git/file-transfer route to move the current repository to the work laptop. Do not move `.env.local`, `.env.foundry.local`, tokens or personal-machine credentials.

On the work laptop, open the repository in the approved IDE and have Copilot inspect:

- `foundry_client.py`
- `server.py`
- `.env.example`
- `test_clearway.py`

### 2. Confirm the Foundry agent endpoint

In Microsoft Foundry, open the existing agent and its **Configure and share** page.

Confirm:

- the intended agent version is active or pinned;
- the Responses protocol is enabled;
- inbound authorization is Microsoft Entra;
- the invoking user/service identity has **Foundry Agent Consumer** or **Foundry User** at the approved agent/project scope;
- the endpoint works from the firewall-approved network.

Copy the full stable endpoint. It should have this shape:

```text
https://<account>.services.ai.azure.com/api/projects/<project>/agents/<agent>/endpoint/protocols/openai/responses
```

Do not place the endpoint in browser JavaScript. Do not use an API key; Microsoft documents Entra authorization for this agent endpoint.

### 3. Configure local work-laptop settings

Create an ignored file:

```powershell
Copy-Item .env.example .env.foundry.local
```

or, in Bash:

```bash
cp .env.example .env.foundry.local
```

Edit only `.env.foundry.local`:

```dotenv
CLEARWAY_FOUNDRY_AGENT_ENDPOINT=https://<account>.services.ai.azure.com/api/projects/<project>/agents/<agent>/endpoint/protocols/openai/responses
CLEARWAY_FOUNDRY_TOKEN_COMMAND=az account get-access-token --scope https://ai.azure.com/.default --query accessToken -o tsv
CLEARWAY_FOUNDRY_TIMEOUT_SECONDS=90
```

Never commit this file. Never put credentials in `config.js`, browser storage, a screenshot or documentation.

### 4. Authenticate with Microsoft Entra

If the approved work-laptop flow uses Azure CLI:

```powershell
az login
az account show
az account get-access-token --scope https://ai.azure.com/.default --query accessToken -o tsv
```

The last command should return a token, but do not paste or save it. If your corporate Foundry test already uses another approved authentication path, set `CLEARWAY_FOUNDRY_TOKEN_COMMAND` to that noninteractive token command or have Copilot adapt `_access_token()` in `foundry_client.py` to the approved `azure-identity` credential. Keep token acquisition server-side.

### 5. Run static and regression checks

```powershell
python -m py_compile server.py foundry_client.py test_clearway.py
node --check app.js
node --check api-client.js
node --check config.js
python -m unittest -v test_clearway.py
```

Expected result: five tests pass. These tests do not fabricate a runtime Foundry result; the only generated output exists inside test code and is never reachable from the demo UI.

### 6. Start Clearway

```powershell
python server.py
```

Expected startup messages:

```text
Clearway UAT server listening on http://127.0.0.1:4173
Runtime source: local synthetic JSON (Supabase disabled)
Microsoft Foundry configured: True
```

Open:

```text
http://127.0.0.1:4173
```

### 7. Verify the health endpoint

PowerShell:

```powershell
Invoke-RestMethod http://127.0.0.1:4173/api/health | ConvertTo-Json
```

Expected facts:

```json
{
  "ok": true,
  "sourceRepository": "local_synthetic_json",
  "analysisService": "microsoft_foundry_agent",
  "foundryConfigured": true,
  "caseCount": 5
}
```

### 8. Run a backend-only live smoke test

PowerShell:

```powershell
$body = @{
  case_id = "PA-3001"
  source_order_id = "ORD-3001"
} | ConvertTo-Json

$result = Invoke-RestMethod `
  -Method Post `
  -Uri http://127.0.0.1:4173/api/v1/evidence-reviews `
  -ContentType "application/json" `
  -Body $body

$result.review | ConvertTo-Json -Depth 6
```

Do not proceed to the UI demonstration unless the response includes:

```json
{
  "resultSource": "microsoft_foundry_agent",
  "state": "more_information_required | clinical_review_required | review_ready",
  "traceId": "<nonempty client request ID>",
  "foundry": {
    "status": "completed"
  }
}
```

Also inspect every result criterion and confirm:

- all four criterion codes are present once;
- all cited document IDs are part of that case's supplied bundle;
- every displayed quote appears exactly in the cited source file;
- there is no approve/deny or medical-necessity decision.

### 9. Run the UI acceptance path

1. Refresh the page.
2. Confirm the selected case says **Awaiting Microsoft Foundry analysis**.
3. Confirm requirements and action counts display `—` or **Not analyzed**.
4. Confirm downstream actions are disabled.
5. Select **Run Foundry evidence review**.
6. Confirm the UI shows the live Foundry loading stages.
7. Confirm the result displays **Foundry response trace** and a nonempty trace ID.
8. Open each policy criterion and verify its exact policy and clinical citations.
9. Disconnect from the approved network or temporarily use an invalid endpoint and rerun once; confirm the UI shows **Foundry evidence review unavailable** and does not display a new completed result.

## Recommended three-case team demonstration

Run and capture one successful response for each synthetic control scenario before the team meeting:

| Case | Designed acceptance scenario | What must be demonstrated |
|---|---|---|
| `PA-3001` | Missing documentation | Foundry identifies a source-evidence gap without inventing support |
| `PA-3002` | Complete package | Every applicable criterion maps to exact source evidence and routes to clinician review |
| `PA-3003` | Conflicting evidence | Foundry retains both source statements; backend routes to clarification instead of resolving the conflict |

These are acceptance expectations based on the synthetic source design—not proof of live agent behavior. The live work-laptop runs must establish the actual outcomes.

## Foundry output contract

The agent must return one JSON object and no surrounding prose:

```json
{
  "schemaVersion": "clearway.evidence-review.v1",
  "analysisSummary": "Short source-grounded summary",
  "criteria": [
    {
      "criterionCode": "C1",
      "status": "supported",
      "rationale": "Why the supplied records support this criterion",
      "policySource": {
        "documentId": "<exact policyId>",
        "locator": "<exact policyLocator>",
        "quote": "<exact policyQuote>"
      },
      "clinicalSources": [
        {
          "documentId": "<allowed source documentId>",
          "locator": "<precise location>",
          "quote": "<exact contiguous source quote>"
        }
      ],
      "missingInformation": []
    }
  ]
}
```

The backend rejects:

- missing, duplicate or additional criteria;
- unknown statuses;
- approval, denial, decision, medical-necessity, recommendation or submission fields;
- a different policy ID, locator or quote;
- clinical document IDs not supplied for the case;
- clinical quotes that do not occur verbatim in the cited source text;
- `supported` without at least one clinical source quote;
- `conflicting` without at least two clinical source quotes.

## Copilot implementation/review prompt

Paste this into the approved work-laptop Copilot session after opening the repository:

```text
Review this Clearway UAT repository as a senior Python/Azure engineer. The runtime must use local synthetic source-only JSON and a real Microsoft Foundry prompt-agent stable Responses endpoint. Supabase, demo-data.js and any precomputed criteria/review results must not participate in the runtime. The browser may send only case_id and source_order_id. The backend must load and validate the bounded case/policy/document bundle, invoke Foundry server-side with Microsoft Entra authentication, validate the exact clearway.evidence-review.v1 contract and exact citations, derive workflow state in code, and fail closed. Do not add API keys or tokens to source files or browser code. First run the existing compile/Node/unittest checks. Then inspect foundry_client.py against the working endpoint/authentication code on this laptop. Make only the smallest changes required for the live endpoint. Start server.py, confirm /api/health reports foundryConfigured true, run PA-3001 through POST /api/v1/evidence-reviews, verify resultSource=microsoft_foundry_agent and exact source quotes, and then exercise the UI. If the endpoint contract differs, adapt only foundry_client.py and retain every server.py validator. Report actual command output and any blocker; do not use a mock or fallback to claim success.
```

## Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| `503 foundry_not_configured` | `.env.foundry.local` missing or endpoint unset | Copy `.env.example`, set the full stable Responses endpoint, restart server |
| `401` or `403` from Foundry | Token audience, sign-in or RBAC mismatch | Reauthenticate; verify Foundry Agent Consumer/Foundry User at agent/project scope |
| Network/timeout error | Work laptop is off the allowed network/IP path | Reconnect through the approved network path; do not bypass the firewall |
| Endpoint-shape configuration error | Project endpoint used instead of stable agent Responses endpoint | Copy the endpoint ending `/endpoint/protocols/openai/responses` |
| `502 foundry_review_failed` with JSON parser error | Agent added prose/Markdown or returned malformed JSON | Tighten the active agent instructions; preserve backend parser and validators |
| Citation validation error | Agent invented, paraphrased or misattributed a quote | Require exact quotes and source IDs; inspect the active prompt/model/version |
| UI stays unanalyzed | Backend call failed or provenance missing | Inspect the API response/server log; do not enable a fixture fallback |

## Go/no-go gate

The demo is ready for the team only when all of these are true on the work laptop:

- [ ] `python -m unittest -v test_clearway.py` passes.
- [ ] `/api/health` reports `foundryConfigured: true`.
- [ ] One live `PA-3001` backend run succeeds.
- [ ] The response says `resultSource: microsoft_foundry_agent`.
- [ ] All four criteria pass source-ID and exact-quote validation.
- [ ] The UI starts unanalyzed and displays results only after the live call.
- [ ] The trace/request ID is visible in the UI.
- [ ] The failure test does not produce or preserve a new completed analysis.
- [ ] `PA-3001`, `PA-3002` and `PA-3003` produce sensible, source-grounded differentiated behavior.
- [ ] No credentials, customer data, PHI or endpoint secrets are exposed in browser code or artifacts.

## Official Microsoft reference

- [Configure and share a Microsoft Foundry agent](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/configure-agent)

Microsoft's current documentation describes a stable endpoint for every agent, a Responses-protocol endpoint, and Microsoft Entra authorization; API-key authentication is not supported for this agent endpoint. Recheck the current documentation if the work-laptop Foundry experience or endpoint contract differs.
