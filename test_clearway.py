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
from foundry_client import FoundryConfigurationError, FoundryOutputError, _responses_endpoint


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


def supported_result(bundle: dict) -> dict:
    """Return source-valid all-supported test data; never used by runtime or UI."""
    result = structurally_valid_result(bundle)
    source = bundle["sourceDocuments"][0]
    quote = next(line.strip() for line in source["text"].splitlines() if line.strip())
    for item, criterion in zip(result["criteria"], bundle["policy"]["criteria"]):
        item.update(
            {
                "status": "supported",
                "rationale": f"Test-only source evidence maps to {criterion['title']}.",
                "clinicalSources": [
                    {
                        "documentId": source["documentId"],
                        "locator": "Test-only exact source location",
                        "quote": quote,
                    }
                ],
                "missingInformation": [],
            }
        )
    return result


class ClearwayBoundaryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.original_endpoint = os.environ.pop("CLEARWAY_FOUNDRY_AGENT_ENDPOINT", None)
        self.original_api_version = os.environ.pop("CLEARWAY_FOUNDRY_API_VERSION", None)

    def tearDown(self) -> None:
        if self.original_endpoint is not None:
            os.environ["CLEARWAY_FOUNDRY_AGENT_ENDPOINT"] = self.original_endpoint
        else:
            os.environ.pop("CLEARWAY_FOUNDRY_AGENT_ENDPOINT", None)
        if self.original_api_version is not None:
            os.environ["CLEARWAY_FOUNDRY_API_VERSION"] = self.original_api_version
        else:
            os.environ.pop("CLEARWAY_FOUNDRY_API_VERSION", None)

    def test_foundry_api_version_is_added_without_losing_existing_query(self) -> None:
        endpoint = "https://example.services.ai.azure.com/endpoint/protocols/openai/responses?region=east"
        self.assertEqual(
            endpoint + "&api-version=v1",
            _responses_endpoint(endpoint),
        )

        os.environ["CLEARWAY_FOUNDRY_API_VERSION"] = "custom-version"
        self.assertEqual(
            "https://example.services.ai.azure.com/endpoint/protocols/openai/responses?api-version=existing&region=east",
            _responses_endpoint(
                "https://example.services.ai.azure.com/endpoint/protocols/openai/responses?api-version=existing&region=east"
            ),
        )
        self.assertTrue(_responses_endpoint(endpoint).endswith("api-version=custom-version"))

        os.environ["CLEARWAY_FOUNDRY_API_VERSION"] = ""
        with self.assertRaises(FoundryConfigurationError):
            _responses_endpoint(endpoint)

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
        self.assertEqual("Moderate", record["submissionBrief"]["readiness"]["level"])
        self.assertEqual(4, len(record["submissionBrief"]["documentationGaps"]))
        self.assertFalse(record["submissionBrief"]["draftLetter"]["readyForClinicianEditing"])

    def test_all_supported_result_builds_source_linked_clinician_draft(self) -> None:
        bundle = server.load_ai_input("PA-3002")
        raw = supported_result(bundle)
        criteria = server.validate_foundry_output(raw, bundle)
        record = server.build_reviewed_case(
            "PA-3002",
            raw,
            {
                "responseId": "resp_ready_test",
                "clientRequestId": "trace_ready_test",
                "model": "test-only",
                "status": "completed",
            },
            criteria,
        )
        brief = record["submissionBrief"]
        self.assertEqual("review_ready", record["review"]["state"])
        self.assertEqual("High", brief["readiness"]["level"])
        self.assertEqual(4, len(brief["requirementsMet"]))
        self.assertEqual([], brief["documentationGaps"])
        self.assertTrue(brief["draftLetter"]["readyForClinicianEditing"])
        self.assertGreaterEqual(len(brief["draftLetter"]["citations"]), 1)
        self.assertNotEqual(raw["analysisSummary"], brief["executiveSummary"])
        known_quotes = {
            source["quote"]
            for item in brief["draftLetter"]["evidenceItems"]
            for source in item["sourceStatements"]
        }
        self.assertTrue(known_quotes)
        for quote in known_quotes:
            self.assertIn(quote, bundle["sourceDocuments"][0]["text"])

    def test_blank_analysis_summary_is_rejected(self) -> None:
        bundle = server.load_ai_input("PA-3001")
        raw = structurally_valid_result(bundle)
        raw["analysisSummary"] = "  "
        with self.assertRaises(FoundryOutputError):
            server.validate_foundry_output(raw, bundle)

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
            context.exception.close()
            self.assertEqual("foundry_not_configured", body["code"])

            for path in ("/data/inputs/PA-3001.json", "/server.py", "/.env.local"):
                with self.assertRaises(HTTPError) as blocked:
                    urlopen(base + path)
                self.assertEqual(404, blocked.exception.code)
                blocked.exception.close()
        finally:
            httpd.shutdown()
            httpd.server_close()
            thread.join(timeout=2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
