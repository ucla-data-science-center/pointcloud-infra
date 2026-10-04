# Adjudication: ChatGPT review of validation prompt v2

2026-10-04. Every claim checked against the repo, AWS, or the cited source before a verdict. ADOPT = change lands where noted. DEFER = needs Tim or collection owners. REJECT = evidence says otherwise.

## Verified true, adopt (code/docs)

| # | Claim | Evidence | Lands in |
|---|---|---|---|
| 1 | Content/local-build extraction isn't retry-safe: if upload succeeds and extraction fails, the next run skips extraction; deleted/corrupted served files aren't repaired | `content.yml:47` extracts only `when: _potree_content_upload is changed`. My "task not handler" comment fixed a different failure, not this one | Role: extract to a digest-named release dir, validate, then switch a symlink; retries check the release dir, not the upload |
| 2 | Additive extraction isn't exact reproduction; removed pages stay published | Documented in runbook as a known limitation, but it matters for withdrawn material | Same fix as 1: each release is complete, old releases pruned |
| 3 | `site-check.sh` accepts 200 or 301 for both hosts, so it would have missed the bare-domain bug | `site-check.sh:17` | Require 301 to `https://www...` for the bare host; add a real data fetch with the www Referer |
| 4 | Cutover moves the IP before a real cert exists (avoidable warning window) | `docs/cutover.md` steps 4-5 | Copy `/etc/letsencrypt` from the legacy box before moving the IP |
| 5 | Pinning is partial: collections `>=`, Molecule image `:latest`, SSM agent `latest` URL | `requirements.yml`, `molecule.yml:25`, `packages.yml:36` | Pin collection versions and image digest; SSM stays `latest` (AWS's documented install path) but note it |
| 6 | Archive mtimes come from git history, so a shallow clone (CI's default) packs differently | `pack_content.py` + `actions/checkout` default depth 1 | Pack script refuses shallow clones with a clear message |
| 7 | SELinux is assumed, not asserted | No task checks enforcing mode or labels | Role: assert enforcing and run `restorecon` on served paths when SELinux is enabled |
| 8 | "Only TLS differs" between staging and prod is wrong | `molecule.yml:3`, ADR 0001 | Fix both to list firewall, reboot, SELinux, SSM, data access |
| 9 | Collections: 9 directories in git, not 10 | `git ls-tree` = 9 (the empty one isn't tracked) | Correct in future prompts/docs |
| 10 | Pages are NOT mostly URL/title/camera variants | Measured: 256/259 set transforms, 257 set material options, 24 load several clouds, 15 have annotations | Any config schema must cover transforms, materials, multiple clouds, annotations |
| 11 | `potree-core` 2.x derives from the Potree-Loader lineage, not Potree 1.8 | Its README says so | Docs: don't assume feature parity |
| 12 | EX294's current name is "Red Hat Certified Advanced System Administrator in Ansible"; AU294 is based on RHEL 10 and Ansible Core 2.16 | Red Hat pages, quoted | Lesson terminology. Rocky 10 decision confirmed. **New, not in ChatGPT's answer:** our pixi env has ansible-core 2.21, the exam stack is 2.16. Add a pinned 2.16 `exam` environment for practice |

## Adopt (design and learning plan)

| # | Recommendation | Note |
|---|---|---|
| 13 | Config layer first; small extension hooks only where repetition is demonstrated; pilot on three representative pages at existing URLs | Matches finding 10 |
| 14 | Ship a small licensed sample cloud for staging; browser test that the cloud actually renders | Fixes the "staging can't load data" gap without touching the prod bucket |
| 15 | Real Rocky 10 ARM host acceptance before cutover (SELinux, firewalld zone, SSM, cert renewal, reboot recovery) | Turns the PR's "not testable in containers" list into a checklist |
| 16 | Lesson: smaller shared core (6 episodes), Rocky port as a transfer exercise after ep 5, Terraform/cutover as a cloud extension, certification as its own track | Still fits Tim's learn-by-switching: the switch comes once the model is stable |
| 17 | Dataverse episodes must work without private access (sanitized fixtures) or be labeled as case study | |
| 18 | Teach that navigator/EEs are controller tooling, separate from Molecule targets and dev containers | |
| 19 | GitHub schedules can lapse; test alert delivery to a named person | Add to runbook |

## Defer (needs Tim or collection owners)

| # | Item | Why deferred |
|---|---|---|
| 20 | Drop the Referer policy for public collections / move data behind CloudFront + OAC | Changes a 639 GB production data bucket; measure 30 days of transfer first |
| 21 | Preservation: separate masters vs derivatives, separate-account copy, restore test | Needs collection owners' input |
| 22 | OIDC deploys from CI | After deploy recovery works; also needs an Ansible transport decision (SSH vs SSM) |
| 23 | Evaluate Giro3D/Piero, iTowns, heritage templates (Vizcaya) | Research spike, good student project |
| 24 | Pilot COPC for new collections | Already in project ideas; owner buy-in |
| 25 | Execution environment as standard runner | After exam env (12); exam practice uses it anyway |

## Reject / clarify

| # | Claim | Finding |
|---|---|---|
| 26 | "`prevent_destroy` protects cutover" is wrong | We never claimed that; the prompt said it protects the EIP from deletion. No change |
| 27 | "Holding RHCSA and passing EX294 leads to RHCE in Ansible" | Partly confirmed: the page says EX294 "counts towards" RHCE in Ansible; it doesn't state the RHCSA requirement there. Check when booking |
| 28 | npm counts | Theirs are for Sept 1-30; ours were rolling 30 days. Both fine; use fixed windows going forward |
