# Clearway backend integration boundary

> **Current runtime:** local synthetic source-only JSON plus a required Microsoft Foundry agent call. Supabase and browser fixtures are disabled.

See [`WORK_LAPTOP_FOUNDRY_HANDOFF.md`](WORK_LAPTOP_FOUNDRY_HANDOFF.md) for the complete work-laptop setup, live smoke test, Copilot prompt and go/no-go checklist.

## Request path

1. Browser posts only `case_id` and `source_order_id` to `POST /api/v1/evidence-reviews`.
2. `server.py` loads the matching local source-only case and `clearway.ai-input.v1` bundle.
3. The backend validates:
   - case/order binding;
   - synthetic-data marker;
   - effective policy date;
   - policy and document hashes;
   - unique fixed criteria;
   - exact received-document manifest coverage.
4. `foundry_client.py` invokes the agent's stable Responses endpoint using Microsoft Entra authentication.
5. The agent performs bounded policy-to-evidence comparison and returns `clearway.evidence-review.v1` JSON.
6. The backend rejects unknown/missing criteria, forbidden decision fields, invalid statuses, unapproved source IDs and non-verbatim quotes.
7. The backend derives `more_information_required`, `clinical_review_required` or `review_ready` and returns the transient result to the browser.
8. The UI renders the result only when `review.resultSource` is `microsoft_foundry_agent`.

## Configuration

Copy `.env.example` to ignored `.env.foundry.local` on the firewall-approved work laptop. Required:

```dotenv
CLEARWAY_FOUNDRY_AGENT_ENDPOINT=https://<account>.services.ai.azure.com/api/projects/<project>/agents/<agent>/endpoint/protocols/openai/responses
CLEARWAY_FOUNDRY_API_VERSION=v1
CLEARWAY_FOUNDRY_TOKEN_COMMAND=az account get-access-token --scope https://ai.azure.com/.default --query accessToken -o tsv
```

No endpoint or token belongs in browser code. The calling identity needs the approved Foundry Agent Consumer or Foundry User role at agent/project scope.

## Fail-closed behavior

| Failure | API behavior | UI behavior |
|---|---|---|
| Foundry not configured | `503 foundry_not_configured` | Remains unanalyzed |
| Network, RBAC or agent failure | `502 foundry_review_failed` | Shows Foundry unavailable; no new result |
| Malformed JSON or contract | `502 foundry_review_failed` | No analysis rendered |
| Invalid source ID or invented quote | `502 foundry_review_failed` | No analysis rendered |
| Missing/invalid input relationship | `400` | No agent call |

There is no deterministic fixture or cached-result fallback in the runtime.

## Test command

```bash
python3 -m unittest -v test_clearway.py
```

A real live-agent pass must be run on the approved work laptop; tests on the personal laptop verify only the local data, API boundary, validators and fail-closed behavior.
