#!/usr/bin/env python3
"""Regression tests for the source-only Clearway + Foundry boundary."""

from __future__ import annotations

import json
import os
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

import server
from foundry_client import FoundryConfigurationError, FoundryOutputError


def structurally_valid_result(bundle: dict) -> dict:
    """Return schema-valid test data; it is never used by the runtime or UI."""
    return {
        "schemaVersion": "clearway.evidence-review.v1",
        "analysisSummary": "Test-only structurally valid output.",
        "criteria": [
            {
                "criterionCode": criterion["criterionCode"],
                "status": "unable_to_assess",
                "rationale": "Test-only output intentionally contains no clinical conclusion.",
                "policySource": {
                    "documentId": bundle["policy"]["policyId"],
                    "locator": criterion["policyLocator"],
                    "quote": criterion["policyQuote"],
                },
                "clinicalSources": [],
                "missingInformation": ["A live Foundry assessment is required."],
            }
            for criterion in bundle["policy"]["criteria"]
        ],
    }


class ClearwayBoundaryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.original_endpoint = os.environ.pop("CLEARWAY_FOUNDRY_AGENT_ENDPOINT", None)

    def tearDown(self) -> None:
        if self.original_endpoint is not None:
            os.environ["CLEARWAY_FOUNDRY_AGENT_ENDPOINT"] = self.original_endpoint
        else:
            os.environ.pop("CLEARWAY_FOUNDRY_AGENT_ENDPOINT", None)

    def test_all_cases_start_unanalyzed_and_inputs_validate(self) -> None:
        workspace = server.load_workspace()
        self.assertEqual(5, len(workspace["cases"]))
        for summary in workspace["cases"]:
            case = server.load_case(summary["id"])
            self.assertEqual("not_analyzed", case["review"]["state"])
            self.assertEqual("not_run", case["review"]["resultSource"])
            self.assertEqual({"pending"}, {item["status"] for item in case["criteria"]})
            server.validate_ai_input(
                server.load_ai_input(case["id"]),
                case["id"],
                case["selectedOrderId"],
            )

    def test_runtime_fails_closed_without_foundry(self) -> None:
        with self.assertRaises(FoundryConfigurationError):
            case = server.load_case("PA-3001")
            server.run_evidence_review(case["id"], case["selectedOrderId"])

    def test_validated_foundry_shape_is_mapped_with_provenance(self) -> None:
        bundle = server.load_ai_input("PA-3001")
        raw = structurally_valid_result(bundle)
        criteria = server.validate_foundry_output(raw, bundle)
        record = server.build_reviewed_case(
            "PA-3001",
            raw,
            {
                "responseId": "resp_test_only",
                "clientRequestId": "trace_test_only",
                "model": "test-only",
                "status": "completed",
            },
            criteria,
        )
        self.assertEqual("microsoft_foundry_agent", record["review"]["resultSource"])
        self.assertEqual("more_information_required", record["review"]["state"])
        self.assertEqual(4, len(record["criteria"]))

    def test_invented_clinical_quote_is_rejected(self) -> None:
        bundle = server.load_ai_input("PA-3001")
        raw = structurally_valid_result(bundle)
        raw["criteria"][0].update(
            {
                "status": "supported",
                "clinicalSources": [
                    {
                        "documentId": bundle["sourceDocuments"][0]["documentId"],
                        "locator": "test",
                        "quote": "This sentence does not exist in the source document.",
                    }
                ],
            }
        )
        with self.assertRaises(FoundryOutputError):
            server.validate_foundry_output(raw, bundle)

    def test_http_api_hides_source_files_and_returns_503_without_foundry(self) -> None:
        httpd = server.ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
        thread = threading.Thread(target=httpd.serve_forever, daemon=True)
        thread.start()
        base = f"http://127.0.0.1:{httpd.server_address[1]}"
        try:
            health = json.loads(urlopen(base + "/api/health").read())
            self.assertEqual("local_synthetic_json", health["sourceRepository"])
            self.assertFalse(health["foundryConfigured"])

            case = json.loads(urlopen(base + "/api/v1/prior-authorization-cases/PA-3001").read())
            self.assertEqual("not_analyzed", case["review"]["state"])

            request = Request(
                base + "/api/v1/evidence-reviews",
                data=json.dumps({"case_id": "PA-3001", "source_order_id": "ORD-3001"}).encode(),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with self.assertRaises(HTTPError) as context:
                urlopen(request)
            self.assertEqual(503, context.exception.code)
            body = json.loads(context.exception.read())
            self.assertEqual("foundry_not_configured", body["code"])

            for path in ("/data/inputs/PA-3001.json", "/server.py", "/.env.local"):
                with self.assertRaises(HTTPError) as blocked:
                    urlopen(base + path)
                self.assertEqual(404, blocked.exception.code)
        finally:
            httpd.shutdown()
            httpd.server_close()
            thread.join(timeout=2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
