#!/usr/bin/env python3
"""Deterministic provider brief and draft-letter view model.

This module never invokes a model and never selects a policy. It transforms an
already validated case and criterion result into provider-facing presentation
content. Every clinical statement in the letter remains linked to an exact
validated source quote.
"""

from __future__ import annotations


def build_submission_brief(
    record: dict,
    criteria: list[dict],
    state: str,
) -> dict:
    applicable = [item for item in criteria if item["status"] != "not_applicable"]
    supported = [item for item in applicable if item["status"] == "supported"]
    unresolved = [item for item in applicable if item["status"] != "supported"]
    source_count = len(
        {
            (source["documentId"], source["locator"], source["quote"])
            for item in supported
            for source in item["clinicalSources"]
        }
    )
    unresolved_verb = "requires" if len(unresolved) == 1 else "require"
    conflict_verb = "contains" if len(unresolved) == 1 else "contain"

    if state == "review_ready":
        readiness = {
            "level": "High",
            "label": "Ready for clinician review",
            "explanation": (
                f"All {len(applicable)} applicable policy criteria have exact source-linked evidence. "
                "Clinician verification and administrative checks still remain."
            ),
        }
    elif state == "clinical_review_required":
        readiness = {
            "level": "Clinical review required",
            "label": "Conflicting evidence must be resolved",
            "explanation": (
                f"{len(unresolved)} of {len(applicable)} applicable criteria {conflict_verb} unresolved or "
                "insufficient evidence. The workflow does not resolve clinical conflicts."
            ),
        }
    else:
        readiness = {
            "level": "Moderate",
            "label": "Documentation completion required",
            "explanation": (
                f"{len(supported)} of {len(applicable)} applicable policy criteria have source-linked "
                f"support; {len(unresolved)} {unresolved_verb} additional or clearer documentation."
            ),
        }

    executive_summary = (
        f"Foundry mapped {len(supported)} of {len(applicable)} applicable policy criteria "
        f"to {source_count} exact clinical source "
        f"citation{'s' if source_count != 1 else ''}. "
        f"{readiness['label']}; clinician verification remains required."
    )

    requirements_met = [
        {
            "criterionId": item["id"],
            "title": item["title"],
            "explanation": (
                f"Mapped to {len(item['clinicalSources'])} exact clinical source "
                f"citation{'s' if len(item['clinicalSources']) != 1 else ''}; "
                "clinician verification required."
            ),
            "sourceCount": len(item["clinicalSources"]),
        }
        for item in supported
    ]

    gaps = []
    for item in unresolved:
        missing = item.get("missingInformation") or []
        if item["status"] == "conflicting":
            impact = "Requires authorized clinical clarification before this draft can be used."
        elif item["status"] == "unable_to_assess":
            impact = "Prevents a reliable submission-readiness assessment until sufficient evidence is supplied."
        else:
            impact = "Prevents a submission-ready evidence package until the source documentation is added."
        gaps.append(
            {
                "criterionId": item["id"],
                "title": item["title"],
                "status": item["status"],
                "missingInformation": missing or [item["description"]],
                "whyRequired": item["policyQuote"],
                "policyLocator": item["policyLocator"],
                "impact": impact,
                "nextAction": item["next"],
            }
        )

    risks = []
    if gaps:
        risks.append(
            {
                "level": "attention",
                "title": "Evidence completeness",
                "detail": (
                    "The draft must not be treated as submission-ready until every highlighted gap "
                    "is resolved in an authorized source record and the Foundry review is rerun."
                ),
            }
        )
    if any(item["status"] == "conflicting" for item in unresolved):
        risks.append(
            {
                "level": "critical",
                "title": "Clinical conflict",
                "detail": "Conflicting source statements remain visible and require an authorized clinician to resolve them.",
            }
        )
    risks.extend(
        [
            {
                "level": "neutral",
                "title": "Administrative verification",
                "detail": "Confirm member, coding, site-of-service, form and payer-portal requirements outside this evidence review.",
            },
            {
                "level": "neutral",
                "title": "Human review boundary",
                "detail": "This evidence map supports preparation; it does not approve, deny or make a medical-necessity determination.",
            },
        ]
    )

    if gaps:
        next_steps = [gap["nextAction"] for gap in gaps]
        next_steps.append("Update only the authorized source record, then rerun the same Foundry evidence review.")
    else:
        next_steps = [
            "Verify each clinical statement against its exact cited source.",
            "Confirm member, procedure-code and payer-specific administrative fields.",
            "Have the authorized clinician edit, attest and sign the draft before any submission.",
        ]

    citation_index: dict[tuple[str, str, str], str] = {}
    citations: list[dict] = []
    evidence_items: list[dict] = []
    for item in supported:
        reference_ids: list[str] = []
        for source in item["clinicalSources"]:
            key = (source["documentId"], source["locator"], source["quote"])
            reference_id = citation_index.get(key)
            if not reference_id:
                reference_id = f"E{len(citations) + 1}"
                citation_index[key] = reference_id
                citations.append({"id": reference_id, **source})
            reference_ids.append(reference_id)
        evidence_items.append(
            {
                "criterionId": item["id"],
                "title": item["title"],
                "sourceStatements": [
                    {
                        "citationId": reference_id,
                        "quote": source["quote"],
                    }
                    for source, reference_id in zip(item["clinicalSources"], reference_ids)
                ],
                "policyQuote": item["policyQuote"],
                "policyLocator": item["policyLocator"],
            }
        )

    orders = record.get("orders") or [{}]
    order = next(
        (item for item in orders if item.get("id") == record.get("selectedOrderId")),
        orders[0],
    )
    policy = record["policy"]
    payer = record["coverage"]["payer"]
    patient = record["patient"]
    policy_reference = (
        f"{policy['name']} ({policy['id']}, version {policy['version']}), effective "
        f"{policy['effectiveStart']} through {policy['effectiveEnd']}"
    )
    completion_required = bool(gaps)
    procedure_code = f"{order.get('codeSystem', '')} {order.get('procedureCode', '')}".strip()
    letter = {
        "title": "Draft medical necessity letter",
        "status": "Completion required" if completion_required else "Ready for clinician editing",
        "readyForClinicianEditing": not completion_required,
        "recipient": f"{payer['name']} Prior Authorization Review Team",
        "subject": f"Prior Authorization Request for {order.get('procedure', 'Requested Service')}",
        "date": "[Date]",
        "memberName": patient.get("name") or "[Member name]",
        "memberId": record["coverage"].get("memberId") or "[Member ID]",
        "caseId": record["id"],
        "diagnosis": "[Confirm diagnosis and ICD-10 code]",
        "requestedService": order.get("procedure") or "[Requested service]",
        "procedureCode": procedure_code or "[Procedure code]",
        "orderingClinician": order.get("orderingClinician") or "[Ordering clinician]",
        "serviceDate": order.get("serviceDate") or "[Planned service date]",
        "openingParagraph": (
            f"This draft supports the prior authorization request for {order.get('procedure', 'the requested service')} "
            f"({procedure_code or 'procedure code to be confirmed'}) for {patient.get('name', 'the member')}. "
            f"The supplied records were mapped against {policy_reference}."
        ),
        "evidenceIntro": "The supplied records contain source-linked evidence for the following policy requirements:",
        "evidenceItems": evidence_items,
        "completionItems": [
            {
                "title": gap["title"],
                "placeholder": "[Obtain and verify: " + "; ".join(gap["missingInformation"]) + "]",
                "policyLocator": gap["policyLocator"],
            }
            for gap in gaps
        ],
        "supportingConclusion": (
            "Subject to clinician verification, the documented findings summarized above support preparation "
            "of this prior authorization request under the cited policy criteria."
            if not completion_required
            else "This draft is intentionally incomplete and must not be submitted until the highlighted documentation gaps are resolved and re-reviewed."
        ),
        "closing": "Please review the enclosed source documentation and cited policy evidence for this request.",
        "citations": citations,
        "disclaimer": (
            "This source-linked draft assists clinical documentation review and prior-authorization preparation. "
            "It requires authorized clinician verification, editing and signature and is not a coverage determination."
        ),
    }

    return {
        "executiveSummary": executive_summary,
        "readiness": readiness,
        "requirementsMet": requirements_met,
        "documentationGaps": gaps,
        "risks": risks,
        "nextSteps": next_steps,
        "draftLetter": letter,
    }
