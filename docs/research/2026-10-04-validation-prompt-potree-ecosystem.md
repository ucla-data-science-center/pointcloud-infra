# Validation prompt: Potree ecosystem, system design, and a learning plan for a university point cloud host

You are reviewing the technical direction, system design, and learning plan for a small university web service that hosts 3D point cloud scans with the open source viewer Potree. I need a skeptical, specific critique, not encouragement. When you state facts about projects, people, adoption, or exam content, give a confidence level and flag anything you can't verify; I will check every claim. If something below is wrong, say so.

The repository is public: https://github.com/ucla-data-science-center/pointcloud-infra (the Rocky Linux work below is in open PR #2).

## 1. Who we are and what we run

The UCLA Library Data Science Center (DSC) runs `pointcloud.ucla.edu`, a public site of research and cultural heritage scans (archaeology in Iceland and Cambodia, a cuneiform tablet collection, anatomy, student projects) viewed in the browser.

- **Current production:** one hand-built EC2 server (Ubuntu 22.04, Apache) serving static files. Potree 1.8.x lives at the web root as `/build` and `/libs`. Point cloud data, already converted with PotreeConverter, is in S3 and loaded by the browser directly.
- **Content:** 10 collection folders with 259 HTML pages. **251 of the 259 are copies of Potree's example template** (about 85 lines each). They load around 13 scripts from `../libs` and `../build`, create a `Potree.Viewer`, set EDL/FOV/point budget, call `viewer.loadGUI()`, then `Potree.loadPointCloud("https://<bucket>.s3.us-west-2.amazonaws.com/<path>/metadata.json", ...)` and set a camera. They differ mainly in data URL, title and camera.
- **Data:** 639 GB in one S3 bucket (946 objects), plus a little in a second bucket. Versioning is on; no lifecycle rules, no replication. Access is a bucket policy allowing public `GetObject` only when the HTTP `Referer` matches `https://www.pointcloud.ucla.edu/*` (hotlink protection). CORS allows `*`. No CDN.
- **People:** one staff maintainer (Tim), a few staff colleagues, and student contributors through the library's open source program office (OSPO).

## 2. What was built in the last day (verify the design, not just the list)

All in one repo, Terraform + Ansible, tooling pinned with pixi:

- **Ansible role `potree`** for **Rocky Linux 10** (switched today from Ubuntu because the Library is a Red Hat shop; Dataverse already runs Rocky 9). httpd + mod_ssl + mod_http2; Potree 1.8.2 release zip pinned by sha256 and symlinked into the web root; certbot from EPEL (webroot challenge, `certbot-renew.timer` enabled); `dnf-automatic` (security updates, reboot when needed); firewalld; SELinux enforcing with every served path under `/var/www` so default labels apply; system crypto policy for TLS (no per-site cipher config); stock `welcome.conf` neutralized; a UCLA Library-branded `mod_autoindex` listing; 301 from any non-`www` host to `www` (production only); `Cache-Control: max-age=86400` on Potree assets; SSM agent for shell access without SSH.
- **Local "staging"** is the same playbook in a Rocky Linux 10 systemd container, run by Molecule with the Podman driver. `molecule test` covers converge, an idempotence run (must report 0 changes), and verify (listing skin, assets, redirect, headers, update timer). It runs on laptops and in GitHub Actions. There is no cloud staging server; Potree upstream changes rarely and the site is static.
- **Content in git:** the collection pages were pulled off the server into the repo, and deploys ship them as one reproducible tarball.
- **Dev loop for Potree itself:** build a local Potree checkout (`npm install`, ~17 s on Node 26) and staging serves it in place of the release.
- **Terraform:** new t4g.small instance (Graviton), official Rocky 10 aarch64 AMI, IMDSv2 only, encrypted 30 GB gp3, SSH limited to admin CIDRs, an SSM role, S3 backend with native lockfile (`use_lockfile`, no DynamoDB). The existing Elastic IP is **imported** with `prevent_destroy`, and a variable `eip_target = "legacy" | "new"` moves it between the old and new server, so cutover and rollback are a one-word change. The plan is 14 add, 1 import, 1 change (tags), 0 destroy. Not applied yet.
- **CI:** pre-commit (yamllint, ansible-lint production profile, terraform fmt/validate, tflint) and Molecule on every PR; a daily scheduled GitHub Action checks HTTP status and cert expiry (Let's Encrypt no longer emails expiry warnings, and the old server's certs silently expired for weeks in August 2026 because its 8 GB disk filled).
- **Docs:** getting-started for students (macOS, Linux, Windows via WSL), contributing guide, project ideas, runbook, cutover plan, five decision records.

## 3. What we found today by measuring

- `https://pointcloud.ucla.edu/` (no `www`) served pages with 200 instead of redirecting. Their Referer didn't match the S3 policy, so **point clouds silently failed to load** for anyone who arrived at the bare domain over HTTPS, which is what modern browsers do when you type the name. Fixed live by hand today and encoded in the role.
- **Staging can't load point cloud data**: its pages run on `localhost`, which the Referer policy rejects. Students can work on everything except the 3D data itself.
- Production served the 2.2 MB `potree.js` with no `Cache-Control`, over HTTP/1.1 only.
- One page points at a missing object (404). Several pages reference a library that doesn't exist in Potree 1.8.2 and already 404s.
- The Potree 1.8.2 release contains every `../build` and `../libs` file the pages actually use (verified by diffing references against the zip).
- The Ubuntu version of the role had a latent bug: the vhost included `/etc/letsencrypt/options-ssl-apache.conf`, which only exists with certbot's Apache plugin, so the first real certificate deploy would have failed.

## 4. The ecosystem as I measured it (October 4, 2026; verify and correct)

| Project | What it is | Signals |
|---|---|---|
| `potree/potree` 1.8.x | The WebGL viewer we run | ~5,600 stars, ~1,370 forks, ~820 open issues+PRs, ~85 open PRs. Last code merge May 2024; only a README commit since (Jan 2026). 1.8.2 added initial COPC and LAS 1.4 support. |
| `potree/PotreeConverter` | C++ LAS/LAZ to Potree octree converter | Active: author commits through Sept 23, 2026. Outside PRs rarely merged (last ~2023). ~187 open issues. |
| `m-schuetz/Potree-Next` | WebGPU rewrite, positioned as the eventual 1.8 replacement; funded by Netidee; goals: 3D Tiles, arbitrary attributes, new format, Gaussian splats | ~124 stars, last push Oct 2025 |
| Author's recent work | CuRast (CUDA rasterization), Splatshop (splat editing), SimLOD, CudaLOD | Research moving to GPU compute and splats |
| `tentone/potree-core` (npm) | Potree's rendering/loading as a three.js library | **~105,000 downloads/month**, v2.0.15 Apr 2026, push Sept 14, 2026, merging outside PRs Aug/Sept 2026; contributors appear to include Cognite staff |
| `@pnext/three-loader` | Potree-format loader for three.js | ~8,100/month |
| `copc` / `@loaders.gl/las` | COPC reader / LAS loader | ~87,000 / ~184,000 per month |
| `itowns` | Geospatial 3D framework with point clouds | ~10,000/month |

Potree 1.8's extension surface: no formal plugin API. A global `Potree` namespace re-exports ~40 modules; `Viewer`/`Scene` dispatch events (`pointcloud_added`, `scene_changed`, `annotation_added`); optional features (`Images360`, `OrientedImages`, `CameraAnimation`) sit in `src/modules/` and are wired into the jQuery/jsTree sidebar by hand.

## 5. Learning goals and the lesson plan

This infrastructure doubles as teaching material:

- **Tim** is preparing for **Red Hat EX294 (RHCE)**. Current published objectives include ansible-navigator and `ansible-navigator.yml`, Ansible development containers, Git, VS Code, static inventories, roles and collections, Vault, templates, and automating RHCSA tasks (packages/repos, services, firewall rules, file systems, storage devices, archiving, scheduling, security, users/groups). Tim learns well by switching between systems and approaches.
- **Students and colleagues** (two staff not pursuing certification) need the core skills without exam-specific material.
- **An existing Carpentries Incubator lesson** (10 episodes, ~2,400 lines) teaches the library's Dataverse infrastructure, but learners can't do its exercises without private access. The plan restructures it into:
  - **Part 1 (pointcloud, hands-on, laptop only):** P1 from hand-built server to desired state; P2 first converge (predict first/second run, separate "no changes" from "site works"); P3 variables/templates/handlers/role; P4 port the role from the tagged Ubuntu version to Rocky (dnf, httpd, firewalld, SELinux); P5 break-fix-rebuild with planted faults; P6 Terraform for an existing server (import, prevent_destroy, EIP switch); P7 monitoring boring failures.
  - **Part 2 (Dataverse):** the existing episodes, lightly edited, then the AI episode.
  - **Optional extras:** an EX294 objective map, and a Terraform-built exam lab (one control node plus three or four managed Rocky VMs, destroyed after each session) for what containers can't practice (storage/LVM, SELinux, firewalld, reboot persistence, ansible-navigator).
  - Exercises move from worked example, to partly finished example, to requirement only, using a specify, predict, attempt, check, explain, transfer cycle.
  - Upstream open source contribution is planned for separate OSPO material, not this lesson.

## 6. Already decided, do not relitigate

Terraform + Ansible + Molecule/Podman staging in one public repo with pixi; Rocky Linux 10; static hosting on one small instance; point cloud data stays in S3; Potree 1.8.2 in production for now; rebuild and cut over via the Elastic IP rather than adopting the old server; content in git.

## 7. What I want from you

**A. Ecosystem and direction (confidence for each)**
1. Is my reading right: 1.8 in maintenance mode, Potree-Next the author's intended future, `potree-core` where outside contributors are active? What am I missing (other forks, distributions, successors with real activity)?
2. Who uses Potree in production (institutions, national LiDAR portals, museums and heritage projects, companies)? How do you know? Mark uncertain items.
3. Who is active and who pays: maintainers, companies, research groups, funding or governance changes?
4. What does this ecosystem need that a university group with students could credibly supply? Rank by value to the ecosystem vs. feasibility for undergraduates.
5. Where is the space heading over 2 to 3 years (COPC, 3D Tiles, Gaussian splats, WebGPU), and which of these should a small static host care about, and when?

**B. A "plugin" architecture for our site**
The 251 copy-pasted pages are the problem. Compare (1) config-driven pages on Potree 1.8 (a `collection.yml` per collection, one shared bootstrap, small ES-module "plugins" hooking viewer events and adding sidebar panels); (2) our own thin viewer on `potree-core` + three.js with an explicit plugin interface; (3) Potree-Next for new collections; (4) anything better (iTowns, Cesium + 3D Tiles, a COPC-first viewer). For each: migration cost, risk if upstream stalls, fit for student contributors, accessibility, maintenance. For your recommendation, sketch the plugin contract (lifecycle hooks, inputs, UI registration, per-collection config), the collection schema, 3 to 5 first plugins, how to test them in our Molecule staging, and what could go upstream.

**C. System improvements: rank these, add what's missing, flag anything wrong**
1. **CloudFront in front of S3** (and maybe the site): HTTP/2 and HTTP/3, edge caching for 639 GB of tiles, origin access control instead of Referer checks. Worth it for our traffic? Cost vs. S3 egress?
2. **Making staging load real data**: add `localhost` to the Referer allow-list, a small public sample bucket, or a sample point cloud shipped in the container. What's cleanest?
3. **Referer-based protection itself**: reasonable hotlink deterrent, or should we drop it or replace it?
4. **Bringing the S3 buckets under Terraform** (import, CORS, policy) and **protecting 639 GB** (versioning is on; cross-region replication, Glacier copy, or nothing?).
5. **Deploying from CI** with GitHub OIDC to AWS (no long-lived keys) vs. keeping deploys manual from a laptop.
6. **ansible-navigator and an execution environment** as the standard way to run the playbook (also matches the exam).
7. **Host monitoring** (CloudWatch agent disk alarm or similar) on top of the external HTTP/cert check.
8. Anything in the Rocky role that's wrong or risky: SELinux approach, firewalld behind a security group, `dnf-automatic` auto-reboots on a single server, EPEL dependency for certbot, system crypto policy, Graviton.

**D. Learning plan critique**
1. Does the Part 1 sequence build skills in a sensible order for a solo adult learner aiming at EX294 and for students who aren't? What would you cut, merge or reorder?
2. What EX294 objectives does this plan still miss, and what's the most efficient way to practice them (our exam lab, Lisenet's sample exam, Sander van Vugt's course, something else)? Is the current exam on RHEL 9 or RHEL 10, and does it matter for practice?
3. Is containers-for-basics plus VMs-for-system-tasks the right split?
4. How do we keep one lesson useful to three audiences (certification seeker, students, staff operators) without it sprawling?

**E. Challenge these assumptions**
1. "Staying on Potree 1.8.2 is fine for a few years." What breaks first?
2. "Students can usefully contribute upstream." Realistic for `potree/potree` given the merge pattern? Better targets? Is carrying fixes in our own fork healthy or a trap?
3. "Potree octree format is the right storage." Should new collections be COPC on S3 instead?
4. "A plugin layer is worth it" for 10 collections and one maintainer.
5. "Rocky Linux 10 now" vs. matching Dataverse on Rocky 9.

## 8. Output format

1. One-paragraph bottom line.
2. A1 to A5 with confidence (0 to 100%) and sources or reasoning.
3. B: comparison table, then the recommended design sketch.
4. C: ranked list with cost/effort/benefit, and corrections.
5. D: specific changes to the learning plan.
6. E: point-by-point.
7. Corrections to any facts in sections 1 to 5.
8. The five things you would do first, in order.
