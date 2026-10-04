# Runbook

How to do routine things, and what to do when something breaks. Every command runs from the repo root.

## Access

- **SSH:** `ssh -i ~/.ssh/potree-test.pem ubuntu@<host>`. Only works from the CIDRs in `admin_ssh_cidrs` (terraform.tfvars).
- **No SSH (off campus, key lost):** AWS Session Manager. `aws ssm start-session --profile ucla-library-dsc --region us-west-2 --target <instance-id>` (needs the Session Manager plugin for the AWS CLI). The instance ID is in `pixi run -- terraform -chdir=terraform output instance_id`.
- **Please don't use VS Code / Cursor Remote on the server.** Their server-side caches (several GB) filled the old 8 GB disk and broke certificate renewal in 2026. Edit here, deploy with Ansible.

## Add or update a collection

1. Copy the collection folder into `content/collections/<Name>/`. Pages should load Potree with relative paths (`../build/potree/potree.js`, `../libs/...`) like the existing ones.
2. Point cloud data goes in S3, not in this repo. Pages reference it by URL.
3. `pixi run staging-up`, then open `https://localhost:8443/<Name>/` and check it loads.
4. Open a PR. After it merges: `pixi run deploy-check` (should only show the collections archive changing), then `pixi run deploy`.

## Remove a collection

Content publishing is additive, so deleting a folder from the repo does not delete it from the server. After the PR merges and deploys, remove it on the server too:

```bash
ssh -i ~/.ssh/potree-test.pem ubuntu@<host> 'sudo rm -rf /var/www/pointcloud/<Name>'
```

## Upgrade Potree

1. Find the release on <https://github.com/potree/potree/releases>.
2. Get its checksum: `curl -sL <zip-url> | shasum -a 256`.
3. Update `potree_version` and `potree_release_checksum` in `ansible/roles/potree/defaults/main.yml`.
4. `pixi run staging-up` and click through several collections, especially ones using extra libraries (`grep -rho '\.\./libs/[^"]*' content/ | sort -u` lists what pages need).
5. `pixi run test`, PR, deploy.

Rollback: set the version back and deploy. Old releases stay unpacked in `/opt/potree/`, so it is just a symlink flip.

## Deploy

```bash
pixi run deploy-check   # dry run with diff; read it
pixi run deploy
pixi run site-check
```

## Certificate problems

Certbot renews automatically (`certbot.timer`) and reloads Apache when it does. The daily Site watch action warns 21 days before expiry.

If the cert is close to expiring or already expired:

```bash
ssh ... 'df -h /'                                   # 1. full disk is the usual cause
ssh ... 'sudo certbot renew --dry-run'              # 2. see the actual error
ssh ... 'sudo certbot renew && sudo systemctl reload apache2'
pixi run site-check
```

Port 80 must stay open: renewal uses the HTTP-01 challenge served from `/var/lib/letsencrypt/webroot`.

## Disk full

```bash
ssh ... 'df -h /; sudo du -xh / --max-depth=2 2>/dev/null | sort -h | tail -15'
```

Usual suspects: `~/.vscode-server`, `~/.cursor-server`, old Potree releases in `/opt/potree/`, `/var/cache/potree/`. Journald is capped at 200 MB by the role. To grow the disk, raise `root_volume_gb` in Terraform and apply, then on the server: `sudo growpart /dev/nvme0n1 1 && sudo resize2fs /dev/nvme0n1p1` (device names differ on older instance types; check `lsblk`).

## Site is down

1. `pixi run site-check` to see what is failing (HTTP vs TLS).
2. `ssh ... 'systemctl status apache2; sudo apache2ctl configtest; sudo tail -50 /var/log/apache2/pointcloud-error.log'`
3. If a recent deploy caused it, revert the PR and deploy again.
4. If the instance itself is broken: during the cutover window, roll back by setting `eip_target = "legacy"` and `pixi run tf-apply`. After the legacy server is gone, rebuild: `terraform apply -replace=aws_instance.web`, then `pixi run deploy`.

## Patching

Security updates install automatically (unattended-upgrades) and the server reboots itself when needed at 10:30 UTC (3:30am Pacific). To patch by hand: `ssh ... 'sudo apt update && sudo apt full-upgrade -y'`.
