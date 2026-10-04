# pointcloud-infra

Everything that runs [pointcloud.ucla.edu](https://www.pointcloud.ucla.edu/), the UCLA Library Data Science Center's [Potree](https://github.com/potree/potree) point cloud viewer: the server, its configuration, and the collection pages it publishes.

If the server disappeared tomorrow, this repo should be enough to bring it back.

**New here, or a student contributor?** Start with [docs/getting-started.md](docs/getting-started.md) (local copy of the site in about 30 minutes, no AWS access needed), then [CONTRIBUTING.md](CONTRIBUTING.md) and [project ideas](docs/project-ideas.md). Want to work on the Potree viewer itself? See [hacking on Potree](docs/hacking-on-potree.md).

## How it fits together

```
 browser ──► pointcloud.ucla.edu (Elastic IP)
                   │
                   ▼
        EC2 Ubuntu 24.04 + Apache          ◄── terraform/   builds the box
        ├── /build, /libs  (Potree 1.8.2)  ◄── ansible/     configures it
        ├── /branding      (UCLA skin)
        └── /<Collection>/*.html           ◄── content/     the pages people visit
                   │
                   ▼  (browser fetches point cloud data directly)
        S3: potree-test2, potree1  (not managed here)
```

- **Terraform** creates the EC2 instance, security group, and instance role, and decides which server the public IP points at.
- **Ansible** installs Apache and Potree, applies the UCLA Library directory listing skin, gets the TLS certificate, and publishes `content/`.
- **Point cloud data** lives in S3 and is loaded by the browser. This repo does not manage those buckets yet.

## Environments

| Environment | Where | Used for |
|---|---|---|
| **staging** | Your laptop: Podman container run by Molecule | Trying any change before it ships: Potree upgrades, Apache config, new collections |
| **production** | EC2, `pointcloud.ucla.edu` | The real site |

There is no cloud staging server. Potree only changes when upstream cuts a release (rarely), and the site is static, so a local container running the exact same playbook catches the problems a second server would. See [ADR 0001](docs/decisions/0001-environments.md).

## Quick start

You need [pixi](https://pixi.sh) and [Podman](https://podman.io). Everything else (Ansible, Molecule, Terraform, linters) comes from `pixi.toml` at pinned versions. Full walkthrough, including Linux and Windows: [docs/getting-started.md](docs/getting-started.md).

```bash
# one time
brew install pixi podman
podman machine init && podman machine start   # macOS only
pixi run setup                                 # Ansible collections + git hooks

# every change
pixi run staging-up        # build/update local staging
open https://localhost:8443/   # click through it (self-signed cert warning is expected)
pixi run test              # full test: build, configure twice (idempotence), verify, tear down
```

## Common tasks

| I want to... | Do this |
|---|---|
| Add or update a collection | Put the folder in `content/collections/`, `pixi run staging-up`, check it, open a PR. After merge: `pixi run deploy`. |
| Work on Potree itself | `pixi run staging-potree-dev ~/src/potree` after building your checkout. See [hacking on Potree](docs/hacking-on-potree.md). |
| Upgrade Potree | Change `potree_version` and `potree_release_checksum` in `ansible/roles/potree/defaults/main.yml`, `pixi run test`, PR, deploy. |
| See what a deploy would change | `pixi run deploy-check` |
| Deploy | `pixi run deploy` |
| Check the live site and certificate | `pixi run site-check` |
| Change AWS resources | Edit `terraform/`, `pixi run tf-plan`, PR with the plan output, then `pixi run tf-apply`. |
| Lint everything | `pixi run lint` (also runs on every commit and in CI) |

Step-by-step procedures, including what to do when something breaks, are in the [runbook](docs/runbook.md).

## Repository layout

```
ansible/
  playbooks/site.yml           the one playbook, used by staging and production
  roles/potree/                Apache, Potree, TLS, branding, maintenance
  molecule/default/            local staging definition + verification tests
  inventory/production/        finds the server by AWS tags (no hard-coded IPs)
terraform/                     production AWS resources (state in S3)
content/collections/           collection pages served at the site root
scripts/site-check.sh          HTTP + certificate expiry check
docs/
  getting-started.md           local setup for new contributors
  hacking-on-potree.md         working on the viewer, contributing upstream
  project-ideas.md             projects sized for students
  runbook.md                   how to do things, how to fix things
  cutover.md                   one-time migration from the hand-built server
  decisions/                   why things are the way they are
.github/workflows/             CI (lint + Molecule) and a daily site watch
```

## Monitoring

`.github/workflows/site-watch.yml` checks the site and certificate expiry every morning and fails (emailing repo watchers) if the site is down or the cert has under 21 days left. Let's Encrypt no longer sends expiry emails, and in August 2026 the old server's certificates expired unnoticed for weeks. Watch this repo to get the alerts.

## Contributing

Students, staff, anyone: see [CONTRIBUTING.md](CONTRIBUTING.md). In short, branch, test in staging, open a PR, and let CI pass. Nothing goes to production without a reviewed PR, and you never need production access to contribute. Questions: datascience@ucla.edu.

## License

BSD 3-Clause. See [LICENSE](LICENSE). Potree itself is BSD-2-Clause and is downloaded from upstream at deploy time, not vendored here.
