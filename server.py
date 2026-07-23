#!/usr/bin/env python3
"""Clearway local UAT server.

Serves the static UI and proxies the browser's opaque case/order requests to
Supabase PostgREST. Database credentials never enter browser assets.
"""

from __future__ import annotations

import copy
import hashlib
import json
import os
import re
import sys
import time
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, quote, unquote, urlparse
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
ENV_PATH = ROOT / ".env.local"
ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,80}$")


def load_env(path: Path) -> None:
    if not path.exists():
        raise RuntimeError(f"Missing local environment file: {path}")
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key.strip(), value)


load_env(ENV_PATH)
SUPABASE_URL = os.environ.get("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = os.environ.get("SUPABASE_PUBLISHABLE_KEY", "")
if not SUPABASE_URL or not SUPABASE_KEY:
    raise RuntimeError("SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are required.")


def supabase_get(resource: str):
    request = Request(
        f"{SUPABASE_URL}/rest/v1/{resource}",
        headers={
            "Accept": "application/json",
            "apikey": SUPABASE_KEY,
            "Authorization": f"Bearer {SUPABASE_KEY}",
            "User-Agent": "Clearway-UAT-Backend/1.0",
        },
        method="GET",
    )
    try:
        with urlopen(request, timeout=8) as response:
            return json.loads(response.read().decode("utf-8"))
    except HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")[:500]
        raise RuntimeError(f"Supabase returned HTTP {error.code}: {detail}") from error
    except URLError as error:
        raise RuntimeError(f"Supabase is unavailable: {error.reason}") from error


def load_workspace():
    rows = supabase_get("clearway_workspace_payload?workspace_id=eq.workspace&select=payload")
    if len(rows) != 1 or "payload" not in rows[0]:
        raise RuntimeError("The Clearway workspace payload is missing or ambiguous.")
    return rows[0]["payload"]


def load_case(case_id: str):
    if not ID_PATTERN.fullmatch(case_id):
        raise ValueError("Invalid case identifier.")
    rows = supabase_get(f"clearway_case_payloads?case_id=eq.{quote(case_id)}&select=payload")
    if len(rows) != 1 or "payload" not in rows[0]:
        raise LookupError(f"Case {case_id} was not found.")
    return rows[0]["payload"]


def load_ai_input(case_id: str):
    """Load the full policy and source-document bundle for server-side review only."""
    if not ID_PATTERN.fullmatch(case_id):
        raise ValueError("Invalid case identifier.")
    rows = supabase_get(f"clearway_ai_case_inputs?case_id=eq.{quote(case_id)}&select=payload")
    if len(rows) != 1 or "payload" not in rows[0]:
        raise LookupError(f"AI input bundle for case {case_id} was not found.")
    return rows[0]["payload"]


def validate_ai_input(bundle: dict, case_id: str, order_id: str) -> dict:
    """Fail closed if policy/document text cannot support a bounded review."""
    if bundle.get("schemaVersion") != "clearway.ai-input.v1" or bundle.get("synthetic") is not True:
        raise RuntimeError("The AI input bundle has an invalid schema or synthetic-data marker.")

    case = bundle.get("case") or {}
    order = case.get("order") or {}
    if case.get("caseId") != case_id or order.get("orderId") != order_id:
        raise RuntimeError("The AI input bundle does not match the selected case and order.")

    policy = bundle.get("policy") or {}
    policy_text = policy.get("policyText") or ""
    criteria = policy.get("criteria") or []
    if len(policy_text) < 500 or not criteria:
        raise RuntimeError("The pinned policy text or criteria are incomplete.")
    for criterion in criteria:
        quote_text = criterion.get("policyQuote") or ""
        if not quote_text or quote_text not in policy_text:
            raise RuntimeError(f"Policy quote validation failed for {criterion.get('criterionCode', 'unknown')}.")

    manifest = bundle.get("documentManifest") or []
    source_documents = bundle.get("sourceDocuments") or []
    present_ids = {item.get("documentId") for item in manifest if item.get("present") is True}
    source_ids = {item.get("documentId") for item in source_documents}
    if not present_ids or present_ids != source_ids:
        raise RuntimeError("The source-document bundle does not match the case manifest.")

    total_chars = 0
    for document in source_documents:
        text = document.get("text") or ""
        expected_hash = document.get("contentHash") or ""
        actual_hash = "sha256:" + hashlib.sha256(text.encode("utf-8")).hexdigest()
        if len(text) < 250 or expected_hash != actual_hash:
            raise RuntimeError(f"Source text or hash validation failed for {document.get('documentId', 'unknown')}.")
        total_chars += len(text)

    return {
        "schemaVersion": bundle["schemaVersion"],
        "sourceDocumentCount": len(source_documents),
        "sourceTextCharacters": total_chars,
        "policyCriterionCount": len(criteria),
        "policyTextCharacters": len(policy_text),
        "validated": True,
    }


def parse_json_body(handler: SimpleHTTPRequestHandler, max_bytes: int = 16384):
    raw_length = handler.headers.get("Content-Length", "0")
    try:
        length = int(raw_length)
    except ValueError as error:
        raise ValueError("Invalid content length.") from error
    if length <= 0 or length > max_bytes:
        raise ValueError("Request body is missing or too large.")
    try:
        return json.loads(handler.rfile.read(length).decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError("Request body must be valid JSON.") from error


def ephemeral_clarification(record: dict, criterion_code: str) -> dict:
    result = copy.deepcopy(record)
    item = next((entry for entry in result.get("criteria", []) if entry.get("id") == criterion_code), None)
    if not item or item.get("status") != "conflicting":
        raise ValueError("The selected criterion does not have an unresolved conflict.")
    item["status"] = "supported"
    item["resolved"] = True
    item["whyFlagged"] = ""
    item.setdefault("clinicalSources", []).append({
        "label": "Signed UAT clinician clarification",
        "quote": "The examination finding is clarified as right ankle dorsiflexion 4/5; the conflicting entry was documented in error.",
        "locator": "DOC-UAT-CLAR-3003 · signed clarification",
    })
    item["next"] = "Resolved by signed UAT clarification. Original sources remain visible in the audit history."
    result.setdefault("documents", []).append({
        "id": "DOC-UAT-CLAR-3003",
        "name": "Signed clinician clarification",
        "date": "Jul 23, 2026",
        "type": "Clarification",
        "present": True,
    })
    stamp = int(time.time())
    result["review"] = {
        "runId": f"RUN-UAT-EPHEMERAL-{stamp}",
        "traceId": f"TRC-UAT-EPHEMERAL-{stamp}",
        "state": "review_ready",
        "stateLabel": "Ready for clinician review",
        "stateMessage": "A signed UAT clarification resolved the conflicting finding. Original evidence remains available for review.",
        "resultSource": "ephemeral_uat_clarification",
    }
    return result


class ClearwayHandler(SimpleHTTPRequestHandler):
    server_version = "ClearwayUAT/1.0"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("X-Frame-Options", "DENY")
        self.send_header("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
        if self.path.startswith("/api/"):
            self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, fmt, *args):
        safe_path = urlparse(self.path).path
        sys.stdout.write(f"{self.address_string()} [{self.log_date_time_string()}] {self.command} {safe_path}\n")
        sys.stdout.flush()

    def send_json(self, status: int, payload) -> None:
        body = json.dumps(payload, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def api_error(self, error: Exception) -> None:
        if isinstance(error, ValueError):
            status = HTTPStatus.BAD_REQUEST
        elif isinstance(error, LookupError):
            status = HTTPStatus.NOT_FOUND
        else:
            status = HTTPStatus.BAD_GATEWAY
        self.send_json(status, {"error": str(error), "type": error.__class__.__name__})

    def do_GET(self):
        parsed = urlparse(self.path)
        decoded_path = unquote(parsed.path)
        path_parts = [part for part in decoded_path.split("/") if part]
        if (
            any(part.startswith(".") for part in path_parts)
            or "__pycache__" in path_parts
            or decoded_path == "/server.py"
            or decoded_path.startswith("/supabase/")
        ):
            self.send_json(HTTPStatus.NOT_FOUND, {"error": "Resource not found."})
            return
        try:
            if parsed.path == "/api/health":
                workspace = load_workspace()
                ai_inputs = supabase_get("clearway_ai_case_inputs?select=case_id")
                self.send_json(HTTPStatus.OK, {
                    "status": "ok",
                    "data_source": "supabase_uat",
                    "patients": len(workspace.get("patients", [])),
                    "cases": len(workspace.get("cases", [])),
                    "ai_input_bundles": len(ai_inputs),
                })
                return
            if parsed.path == "/api/v1/prior-authorizations/workspace":
                self.send_json(HTTPStatus.OK, load_workspace())
                return
            prefix = "/api/v1/prior-authorization-cases/"
            if parsed.path.startswith(prefix):
                case_id = parsed.path[len(prefix):]
                if "/" in case_id or not case_id:
                    raise ValueError("Invalid case route.")
                self.send_json(HTTPStatus.OK, load_case(case_id))
                return
        except Exception as error:
            self.api_error(error)
            return
        super().do_GET()

    def do_POST(self):
        parsed = urlparse(self.path)
        try:
            if parsed.path == "/api/v1/evidence-reviews":
                request = parse_json_body(self)
                case_id = str(request.get("case_id", ""))
                order_id = str(request.get("source_order_id", ""))
                if not ID_PATTERN.fullmatch(case_id) or not ID_PATTERN.fullmatch(order_id):
                    raise ValueError("A valid case_id and source_order_id are required.")
                record = load_case(case_id)
                if order_id not in {item.get("id") for item in record.get("orders", [])}:
                    raise ValueError("The selected order does not belong to the selected case.")
                ai_input = load_ai_input(case_id)
                input_summary = validate_ai_input(ai_input, case_id, order_id)
                record.setdefault("review", {})["inputBundle"] = input_summary
                self.send_json(HTTPStatus.OK, record)
                return

            match = re.fullmatch(r"/api/v1/prior-authorization-cases/([A-Za-z0-9_-]+)/clarifications", parsed.path)
            if match:
                request = parse_json_body(self)
                case_id = match.group(1)
                criterion_code = str(request.get("criterion_id", ""))
                record = load_case(case_id)
                self.send_json(HTTPStatus.OK, ephemeral_clarification(record, criterion_code))
                return

            self.send_json(HTTPStatus.NOT_FOUND, {"error": "API route not found."})
        except Exception as error:
            self.api_error(error)


def main() -> None:
    host = os.environ.get("CLEARWAY_HOST", "127.0.0.1")
    port = int(os.environ.get("CLEARWAY_PORT", "8788"))
    server = ThreadingHTTPServer((host, port), ClearwayHandler)
    print(f"Clearway UAT server listening on http://{host}:{port}")
    print("Data source: Supabase synthetic UAT views")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
