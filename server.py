#!/usr/bin/env python3
"""Clearway local synthetic-data and Microsoft Foundry UAT server.

Runtime boundary:
- local JSON files are the synthetic source-of-record for the UAT demo;
- the backend validates one case/order/policy/document bundle;
- a configured Microsoft Foundry agent performs the evidence comparison;
- the backend validates every criterion, source ID, locator, and exact quote;
- no precomputed analysis or silent fallback is returned.
"""

from __future__ import annotations

import copy
import hashlib
import json
import os
import re
from datetime import datetime, timezone
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

from foundry_client import (
    FoundryConfigurationError,
    FoundryInvocationError,
    FoundryOutputError,
    foundry_is_configured,
    invoke_foundry_agent,
)
from submission_brief import build_submission_brief

ROOT = Path(__file__).resolve().parent
DATA_ROOT = ROOT / "data"
ALLOWED_STATUSES = {
    "supported",
    "not_evidenced",
    "conflicting",
    "unable_to_assess",
    "not_applicable",
}
PROHIBITED_OUTPUT_KEYS = {
    "approval",
    "approved",
    "denial",
    "denied",
    "decision",
    "medicalnecessity",
    "medicalnecessitydecision",
    "priorauthorizationdecision",
    "recommendation",
    "submit",
    "submission",
}
SAFE_STATIC_PATHS = {
    "/",
    "/index.html",
    "/provider-ui.css",
    "/config.js",
    "/api-client.js",
    "/app.js",
    "/foundry-enterprise-harness-walkthrough.html",
    "/ui-screenshot.png",
    "/ui-mobile-screenshot.png",
}


def load_env(path: Path) -> None:
    """Load optional local settings without overwriting the process environment."""
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


load_env(ROOT / os.environ.get("CLEARWAY_ENV_FILE", ".env.foundry.local"))


def _load_json(path: Path) -> dict:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise LookupError(f"Synthetic source file not found: {path.name}") from error
    except json.JSONDecodeError as error:
        raise RuntimeError(f"Synthetic source file is invalid JSON: {path.name}") from error
    if not isinstance(payload, dict):
        raise RuntimeError(f"Synthetic source file must contain one JSON object: {path.name}")
    return payload


def load_workspace() -> dict:
    return copy.deepcopy(_load_json(DATA_ROOT / "workspace.json"))


def _case_path(case_id: str) -> Path:
    if not re.fullmatch(r"PA-[A-Z0-9-]+", case_id or ""):
        raise ValueError("case_id has an invalid format")
    return DATA_ROOT / "cases" / f"{case_id}.json"


def load_case(case_id: str) -> dict:
    return copy.deepcopy(_load_json(_case_path(case_id)))


def load_ai_input(case_id: str) -> dict:
    _case_path(case_id)  # Validate before building the second path.
    return copy.deepcopy(_load_json(DATA_ROOT / "inputs" / f"{case_id}.json"))


def _sha256(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def validate_ai_input(payload: dict, case_id: str, source_order_id: str) -> dict:
    errors: list[str] = []
    if payload.get("schemaVersion") != "clearway.ai-input.v1":
        errors.append("schemaVersion must equal clearway.ai-input.v1")
    if payload.get("synthetic") is not True:
        errors.append("synthetic must be true")

    case = payload.get("case") or {}
    policy = payload.get("policy") or {}
    if case.get("caseId") != case_id:
        errors.append("case.caseId does not match the requested case")
    if (case.get("order") or {}).get("orderId") != source_order_id:
        errors.append("case.order.orderId does not match source_order_id")
    for field in ("patient", "coverage", "order"):
        if not case.get(field):
            errors.append(f"case.{field} is required")

    request_date = str(case.get("requestDate") or "")
    start = str(policy.get("effectiveStart") or "")
    end = str(policy.get("effectiveEnd") or "")
    if not (start and request_date and end and start <= request_date <= end):
        errors.append("the pinned policy is not effective on the request date")

    policy_text = str(policy.get("policyText") or "")
    if not policy_text:
        errors.append("policy.policyText is required")
    if policy.get("contentHash") and f"sha256:{_sha256(policy_text)}" != policy.get("contentHash"):
        errors.append("policy.contentHash does not match policy.policyText")

    criteria = policy.get("criteria") or []
    criterion_codes = [item.get("criterionCode") for item in criteria if isinstance(item, dict)]
    if not criteria or len(criterion_codes) != len(set(criterion_codes)) or any(not code for code in criterion_codes):
        errors.append("policy criteria must have unique nonempty criterionCode values")

    manifest = payload.get("documentManifest") or []
    manifest_by_id = {
        item.get("documentId"): item
        for item in manifest
        if isinstance(item, dict) and item.get("documentId")
    }
    present_ids = {
        document_id
        for document_id, item in manifest_by_id.items()
        if item.get("present") is True and item.get("status") == "received"
    }
    source_documents = payload.get("sourceDocuments") or []
    source_ids = [item.get("documentId") for item in source_documents if isinstance(item, dict)]
    if len(source_ids) != len(set(source_ids)) or any(not item for item in source_ids):
        errors.append("sourceDocuments must have unique nonempty documentId values")
    if set(source_ids) != present_ids:
        errors.append("sourceDocuments must exactly match received/present manifest documents")

    for document in source_documents:
        document_id = document.get("documentId")
        text = str(document.get("text") or "")
        if not text:
            errors.append(f"source document {document_id or '<missing-id>'} has empty text")
        expected_hash = document.get("contentHash")
        if expected_hash and f"sha256:{_sha256(text)}" != expected_hash:
            errors.append(f"source document {document_id} contentHash does not match text")
        manifest_hash = (manifest_by_id.get(document_id) or {}).get("contentHash")
        if expected_hash and manifest_hash and expected_hash != manifest_hash:
            errors.append(f"source document {document_id} hash differs from the manifest")

    if errors:
        raise ValueError("AI input validation failed: " + "; ".join(errors))
    return {
        "caseId": case_id,
        "sourceOrderId": source_order_id,
        "policyVersionId": policy.get("policyVersionId"),
        "criterionCount": len(criteria),
        "sourceDocumentCount": len(source_documents),
        "manifestDocumentCount": len(manifest),
    }


def _normalize_key(key: object) -> str:
    return re.sub(r"[^a-z0-9]", "", str(key).lower())


def _reject_prohibited_keys(value: object, path: str = "$") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            if _normalize_key(key) in PROHIBITED_OUTPUT_KEYS:
                raise FoundryOutputError(f"Prohibited decision field returned at {path}.{key}")
            _reject_prohibited_keys(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            _reject_prohibited_keys(child, f"{path}[{index}]")


def _require_string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise FoundryOutputError(f"{label} must be a nonempty string")
    return value.strip()


def validate_foundry_output(result: dict, bundle: dict) -> list[dict]:
    _reject_prohibited_keys(result)
    if result.get("schemaVersion") != "clearway.evidence-review.v1":
        raise FoundryOutputError("schemaVersion must equal clearway.evidence-review.v1")
    _require_string(result.get("analysisSummary"), "analysisSummary")

    policy = bundle["policy"]
    expected_criteria = {
        item["criterionCode"]: item
        for item in policy["criteria"]
    }
    returned = result.get("criteria")
    if not isinstance(returned, list):
        raise FoundryOutputError("criteria must be an array")
    returned_codes = [item.get("criterionCode") for item in returned if isinstance(item, dict)]
    if len(returned_codes) != len(returned) or set(returned_codes) != set(expected_criteria):
        raise FoundryOutputError("criteria must contain every supplied criterionCode exactly once")
    if len(returned_codes) != len(set(returned_codes)):
        raise FoundryOutputError("criterionCode values must be unique")

    source_documents = {
        item["documentId"]: item
        for item in bundle["sourceDocuments"]
    }
    validated: list[dict] = []
    for item in returned:
        code = item["criterionCode"]
        expected = expected_criteria[code]
        status = item.get("status")
        if status not in ALLOWED_STATUSES:
            raise FoundryOutputError(f"{code}.status is not allowed")
        rationale = _require_string(item.get("rationale"), f"{code}.rationale")

        policy_source = item.get("policySource")
        if not isinstance(policy_source, dict):
            raise FoundryOutputError(f"{code}.policySource must be an object")
        if policy_source.get("documentId") != policy.get("policyId"):
            raise FoundryOutputError(f"{code}.policySource.documentId is not the pinned policy")
        if policy_source.get("locator") != expected.get("policyLocator"):
            raise FoundryOutputError(f"{code}.policySource.locator does not match the pinned criterion")
        if policy_source.get("quote") != expected.get("policyQuote"):
            raise FoundryOutputError(f"{code}.policySource.quote does not exactly match the pinned policy quote")

        raw_sources = item.get("clinicalSources")
        if not isinstance(raw_sources, list):
            raise FoundryOutputError(f"{code}.clinicalSources must be an array")
        clinical_sources: list[dict] = []
        for index, source in enumerate(raw_sources):
            if not isinstance(source, dict):
                raise FoundryOutputError(f"{code}.clinicalSources[{index}] must be an object")
            document_id = source.get("documentId")
            document = source_documents.get(document_id)
            if not document:
                raise FoundryOutputError(f"{code} cited an unavailable clinical document: {document_id}")
            quote = _require_string(source.get("quote"), f"{code}.clinicalSources[{index}].quote")
            if quote not in str(document.get("text") or ""):
                raise FoundryOutputError(f"{code} returned a clinical quote not found verbatim in {document_id}")
            locator = _require_string(source.get("locator"), f"{code}.clinicalSources[{index}].locator")
            clinical_sources.append(
                {
                    "documentId": document_id,
                    "label": document.get("title") or document_id,
                    "quote": quote,
                    "locator": locator,
                }
            )

        if status == "supported" and not clinical_sources:
            raise FoundryOutputError(f"{code} cannot be supported without a clinical source quote")
        if status == "conflicting" and len(clinical_sources) < 2:
            raise FoundryOutputError(f"{code} cannot be conflicting without at least two source quotes")

        missing = item.get("missingInformation")
        if not isinstance(missing, list) or any(not isinstance(entry, str) or not entry.strip() for entry in missing):
            raise FoundryOutputError(f"{code}.missingInformation must be an array of nonempty strings")

        if status == "supported":
            next_action = "Verify the cited evidence during clinician review."
        elif status == "not_evidenced":
            next_action = "Obtain: " + ("; ".join(entry.strip() for entry in missing) or expected["description"])
        elif status == "conflicting":
            next_action = "Resolve the conflicting source evidence before clinician handoff."
        elif status == "unable_to_assess":
            next_action = "Obtain sufficient source evidence for a reliable assessment."
        else:
            next_action = "No action required for this criterion."

        validated.append(
            {
                "id": code,
                "criterionId": expected.get("criterionId"),
                "title": expected["title"],
                "description": expected["description"],
                "status": status,
                "resolved": False,
                "whyFlagged": rationale if status == "conflicting" else "",
                "rationale": rationale,
                "policyQuote": expected["policyQuote"],
                "policyLocator": expected["policyLocator"],
                "clinicalSources": clinical_sources,
                "missingInformation": [entry.strip() for entry in missing],
                "next": next_action,
            }
        )
    order = {item["criterionCode"]: index for index, item in enumerate(policy["criteria"])}
    return sorted(validated, key=lambda item: order[item["id"]])


def _workflow(criteria: list[dict]) -> tuple[str, str, str]:
    statuses = {item["status"] for item in criteria}
    if "conflicting" in statuses:
        return (
            "clinical_review_required",
            "Clinical clarification required",
            "The Foundry review found conflicting source evidence. The workflow retained every cited statement and did not resolve the clinical conflict.",
        )
    if statuses & {"not_evidenced", "unable_to_assess"}:
        return (
            "more_information_required",
            "More information required",
            "The Foundry review identified missing or insufficient source evidence. Collect the highlighted documentation before clinician handoff.",
        )
    return (
        "review_ready",
        "Ready for clinician review",
        "Foundry mapped every applicable policy criterion to validated source evidence. An authorized clinician must verify the result before use.",
    )


def build_reviewed_case(case_id: str, result: dict, metadata: dict, criteria: list[dict]) -> dict:
    record = load_case(case_id)
    state, state_label, state_message = _workflow(criteria)
    response_id = metadata.get("responseId") or metadata["clientRequestId"]
    record["criteria"] = criteria
    record["scenario"] = state
    record["review"] = {
        "runId": response_id,
        "traceId": metadata["clientRequestId"],
        "state": state,
        "stateLabel": state_label,
        "stateMessage": state_message,
        "resultSource": "microsoft_foundry_agent",
        "analysisSummary": str(result.get("analysisSummary") or "").strip(),
        "completedAt": datetime.now(timezone.utc).isoformat(),
        "foundry": {
            "responseId": metadata.get("responseId"),
            "clientRequestId": metadata["clientRequestId"],
            "model": metadata.get("model"),
            "status": metadata.get("status"),
        },
    }
    record["submissionBrief"] = build_submission_brief(
        record,
        criteria,
        state,
    )
    return record


def run_evidence_review(case_id: str, source_order_id: str) -> dict:
    record = load_case(case_id)
    if source_order_id not in {item.get("id") for item in record.get("orders") or []}:
        raise ValueError("source_order_id is not linked to the requested case")
    bundle = load_ai_input(case_id)
    validate_ai_input(bundle, case_id, source_order_id)
    raw_result, metadata = invoke_foundry_agent(bundle)
    criteria = validate_foundry_output(raw_result, bundle)
    return build_reviewed_case(case_id, raw_result, metadata, criteria)


def api_error(error: Exception) -> tuple[int, dict]:
    if isinstance(error, LookupError):
        return HTTPStatus.NOT_FOUND, {"error": str(error)}
    if isinstance(error, ValueError):
        return HTTPStatus.BAD_REQUEST, {"error": str(error)}
    if isinstance(error, FoundryConfigurationError):
        return HTTPStatus.SERVICE_UNAVAILABLE, {"error": str(error), "code": "foundry_not_configured"}
    if isinstance(error, (FoundryInvocationError, FoundryOutputError)):
        return HTTPStatus.BAD_GATEWAY, {"error": str(error), "code": "foundry_review_failed"}
    return HTTPStatus.INTERNAL_SERVER_ERROR, {"error": "Internal server error"}


class Handler(SimpleHTTPRequestHandler):
    server_version = "ClearwayUAT/2.0"

    def log_message(self, format: str, *args: object) -> None:
        print(f"[{self.log_date_time_string()}] {format % args}")

    def send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def read_json(self) -> dict:
        length = int(self.headers.get("Content-Length") or 0)
        if length < 1 or length > 1_000_000:
            raise ValueError("Request body must contain one JSON object under 1 MB")
        payload = json.loads(self.rfile.read(length).decode("utf-8"))
        if not isinstance(payload, dict):
            raise ValueError("Request body must be a JSON object")
        return payload

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        try:
            if parsed.path == "/api/health":
                workspace = load_workspace()
                self.send_json(
                    HTTPStatus.OK,
                    {
                        "ok": True,
                        "sourceRepository": "local_synthetic_json",
                        "analysisService": "microsoft_foundry_agent",
                        "foundryConfigured": foundry_is_configured(),
                        "caseCount": len(workspace.get("cases") or []),
                    },
                )
                return
            if parsed.path == "/api/v1/prior-authorizations/workspace":
                self.send_json(HTTPStatus.OK, load_workspace())
                return
            match = re.fullmatch(r"/api/v1/prior-authorization-cases/([^/]+)", parsed.path)
            if match:
                self.send_json(HTTPStatus.OK, load_case(match.group(1)))
                return
            if parsed.path.startswith("/api/"):
                self.send_json(HTTPStatus.NOT_FOUND, {"error": "API route not found"})
                return
            if parsed.path not in SAFE_STATIC_PATHS:
                self.send_error(HTTPStatus.NOT_FOUND)
                return
            super().do_GET()
        except Exception as error:
            status, payload = api_error(error)
            self.send_json(status, payload)

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        try:
            if parsed.path == "/api/v1/evidence-reviews":
                payload = self.read_json()
                case_id = str(payload.get("case_id") or "").strip()
                source_order_id = str(payload.get("source_order_id") or "").strip()
                self.send_json(HTTPStatus.OK, run_evidence_review(case_id, source_order_id))
                return
            if re.fullmatch(r"/api/v1/prior-authorization-cases/[^/]+/clarifications", parsed.path):
                self.send_json(
                    HTTPStatus.CONFLICT,
                    {
                        "error": "Clarification simulation is disabled. Update the authorized source record and rerun the Foundry review.",
                        "code": "source_update_required",
                    },
                )
                return
            self.send_json(HTTPStatus.NOT_FOUND, {"error": "API route not found"})
        except json.JSONDecodeError:
            self.send_json(HTTPStatus.BAD_REQUEST, {"error": "Request body is not valid JSON"})
        except Exception as error:
            status, payload = api_error(error)
            self.send_json(status, payload)


if __name__ == "__main__":
    os.chdir(ROOT)
    port = int(os.environ.get("PORT", "4173"))
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"Clearway UAT server listening on http://127.0.0.1:{port}")
    print("Runtime source: local synthetic JSON (Supabase disabled)")
    print(f"Microsoft Foundry configured: {foundry_is_configured()}")
    server.serve_forever()
