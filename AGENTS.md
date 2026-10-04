# AGENTS.md

Guidance for AI coding agents (and people) working in this repo.

## Canonical context
- Project key: `pointcloud` in `~/projects/project-registry.yaml`
- Hub note: `~/obsidian/projects/Pointcloud.md` (tasks, decisions, status)
- Repo path: `~/projects/pointcloud-infra`

## Ground rules
- Every tool runs through pixi: `pixi run <task>` or `pixi run -- <command>`. Do not install Ansible, Molecule, or Terraform globally for this repo.
- Test every Ansible change in local staging (`pixi run test`) before it touches production.
- Production changes go through a PR. Run `pixi run deploy-check` and include the diff in the PR when it matters.
- Never run `terraform apply` or `pixi run deploy` without the maintainer saying so in the current session.
- `content/collections/` is published content authored by DSC staff and students. Do not rewrite pages; fix only what is asked.
- The Elastic IP (`aws_eip.public`) has `prevent_destroy`. Do not remove that.
- License is BSD-3-Clause.

## Gotchas
- Production and staging are Rocky Linux 10 (Red Hat family, like the rest of the Library). The last Ubuntu version is the `ubuntu-baseline` tag, kept as a teaching starting point.
- Stock `/etc/httpd/conf.d/welcome.conf` disables the listing at `/`; the role neutralizes it. If the home page shows the Rocky test page, that file came back.
- Keep everything httpd serves under `/var/www` so SELinux labels are right by default. Containers don't enforce SELinux, so Molecule won't catch a mistake here; production will.
- ansible-core 2.17+ refuses non-blocking stdio. If you see "Ansible requires blocking IO", pipe output through `| cat`.
- The directory listing skin depends on `IndexStyleSheet`; without it Apache omits `table#indexlist` and the CSS stops matching.
- Collection pages load `../build` and `../libs`, so Potree must live at the web root (the role symlinks the active release there).
