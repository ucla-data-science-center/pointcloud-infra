# 0004: Collection pages live in this repo

Date: 2026-10-04 · Status: accepted

## Context
Collection pages (HTML that sets up a Potree viewer for a dataset) existed only on the server, uploaded by hand. There was no backup and no history. The point cloud data itself is in S3.

## Decision
Pages live in `content/collections/` and Ansible publishes them. Point cloud data stays in S3, referenced by URL.

## Consequences
- Pages are versioned, reviewed, and recoverable.
- Publishing a new collection means a PR, which is slower than scp. That is the point, but it means student workers need a short git walkthrough.
- Deploys pack content into a reproducible tarball (file times = last git commit), so unchanged content never re-uploads. Pages imported on 2026-10-04 show that date in the listing; original upload dates (2023 to 2026) were not kept.
- Removing a page from git does not remove it from the server; see the runbook.
