# 0001: Local staging, EC2 production

Date: 2026-10-04 · Status: accepted

## Context
Dataverse has dev, test, and prod servers. Pointcloud is a static Apache site. Its only moving parts are the Potree release (upstream ships roughly once a year; 1.8.2 was December 2023), Apache config, and collection pages.

## Decision
Two environments. Staging is a Podman container on the maintainer's laptop, built by Molecule from the same playbook production uses (only TLS differs: self-signed). Production is EC2. CI runs the same Molecule scenario on every PR.

## Consequences
- No second server to pay for, patch, or let drift.
- Things a container cannot show (real DNS, Let's Encrypt, AWS networking) are checked during deploy with `deploy-check` and `site-check`.
- If the site grows dynamic parts (a database, uploads, auth), revisit this and add a cloud staging server.
