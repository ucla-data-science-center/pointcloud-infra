# 0002: Rebuild production from code, cut over by Elastic IP

Date: 2026-10-04 · Status: proposed (awaiting go-ahead)

## Context
The existing server was configured by hand starting in 2023. At last check it was Ubuntu 22.04 on a t2.large (gp2), up 24 weeks with a reboot pending and 12 updates queued. Potree was a source checkout, not a git clone, and an extra 8 GB volume was attached with no known purpose. Its 8 GB disk filled in August 2026, which silently broke certificate renewal for weeks.

## Decision
Build a new Rocky Linux 10 server (see ADR 0005) with Terraform + Ansible, test it under the real hostname, then move the existing Elastic IP to it. Keep the old server stopped as a rollback for two weeks.

The alternative was writing Ansible to match the current box and running it in check mode until it reports no changes. That proves the code matches the drift, not that it can rebuild the server, and it keeps the old OS.

## Consequences
- The rebuild is the test: if it serves the site, the repo really does describe the server.
- The whole web root is about 120 MB plus S3-hosted data, so migration is cheap.
- One to two minutes of certificate warnings at cutover while certbot issues a cert for the new host. Avoidable by copying `/etc/letsencrypt` across first if that matters.
