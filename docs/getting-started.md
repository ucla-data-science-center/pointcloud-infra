# Getting started

This guide takes you from nothing to a working copy of pointcloud.ucla.edu running on your own laptop. Plan on about 30 minutes the first time, mostly downloads.

You don't need an AWS account, server access, or any special permissions. Everything here runs locally.

## What you're setting up

pointcloud.ucla.edu is a web server that shows 3D scans (point clouds) in the browser using an open source viewer called [Potree](https://github.com/potree/potree). This repo describes that server as code, and you'll run an exact copy of it in a container on your laptop. We call that copy **staging**. Anything you change, you try in staging first.

## 1. Install the tools

You need three things: **git**, **pixi** (installs everything else at the right versions), and **Podman** (runs the container).

### macOS

```bash
brew install git pixi podman
podman machine init
podman machine start
```

No Homebrew? Install it from <https://brew.sh> first.

### Linux

```bash
sudo apt install git podman      # Fedora: sudo dnf install git podman
curl -fsSL https://pixi.sh/install.sh | bash
```

### Windows

Ansible doesn't run on Windows directly, so you'll work inside Linux using WSL.

1. Open PowerShell as administrator and run `wsl --install -d Ubuntu-24.04`. Restart when asked.
2. Open the **Ubuntu** app. Everything from here on happens in that window.
3. Follow the Linux steps above.

Keep your clone inside the Linux file system (`~/...`), not under `/mnt/c/`. It is much faster.

> The Windows path hasn't been tested end to end yet. If you're the first to try it, please note what worked and what didn't and send a PR to this page.

## 2. Get the code

```bash
git clone https://github.com/ucla-data-science-center/pointcloud-infra.git
cd pointcloud-infra
pixi run setup
```

The first `pixi` command downloads Ansible, Molecule, Terraform and the linters into `.pixi/` inside the repo. Nothing gets installed system-wide.

## 3. Start staging

```bash
pixi run staging-up
```

This builds a Rocky Linux container (the same OS as production) and configures it with the same Ansible playbook production uses. The first run takes a few minutes. When it finishes, open:

**<https://localhost:8443/>**

Your browser will warn about the certificate. That's expected (staging uses a self-signed cert), so click through. You should see the UCLA Library directory listing with the collections. Open `Iceland/` and pick a page to load a point cloud.

## 4. Make a change and see it

Try something small. Open `ansible/roles/potree/files/branding/ucla-index.css`, change a color, then:

```bash
pixi run staging-up
```

Reload the page. Ansible only changes what's different, so this run is quick.

## 5. Run the tests

```bash
pixi run lint     # style and correctness checks
pixi run test     # builds a fresh container, configures it twice, checks the site, tears it down
```

`pixi run test` is what CI runs on your pull request, so if it passes here it will almost always pass there.

## 6. Clean up

```bash
pixi run staging-down
```

## Useful commands

| Command | What it does |
|---|---|
| `pixi run staging-up` | Build or update your local copy of the site |
| `pixi run staging-shell` | Open a shell inside the staging container |
| `pixi run staging-verify` | Re-run the checks against running staging |
| `pixi run staging-down` | Delete the staging container |
| `pixi run staging-potree-dev <path>` | Serve your own Potree build (see [hacking on Potree](hacking-on-potree.md)) |
| `pixi run lint` / `pixi run test` | Checks CI will run |

## When something goes wrong

- **`Cannot connect to Podman`**: on macOS, `podman machine start`. On WSL, make sure you're in the Ubuntu window.
- **Port 8443 or 8080 already in use**: `pixi run staging-down`, or stop whatever else is using the port.
- **`Ansible requires blocking IO`**: some terminals and tools trigger this. Add `| cat` to the end of the command.
- **Anything else**: open an issue with the command you ran and the full error, or ask in the DSC channel. Getting stuck on setup is normal; it's not you.

Next: read [CONTRIBUTING.md](../CONTRIBUTING.md) for how to pick something to work on and send a pull request.
