# Clearway local synthetic source repository

These files are a one-time, source-only export of the synthetic prior-authorization UAT data. They replace Supabase at runtime.

- `workspace.json` contains the selectable synthetic work queue.
- `cases/` contains patient, case, order, coverage, policy metadata, expected-document manifests, and **pending** policy criteria.
- `inputs/` contains the bounded synthetic policy text, criteria, document manifest, and full received source-document text passed by the backend to Microsoft Foundry.

No file contains a completed evidence review. Every case starts with `review.state = not_analyzed` and every criterion starts with `status = pending`. The UI may display analyzed results only after the backend receives and validates a live Foundry agent response.

All data is synthetic. Do not replace these files with PHI or client/customer data.
