# 0005: Rocky Linux 10 instead of Ubuntu

Date: 2026-10-04 · Status: accepted

## Context
The first version of this repo targeted Ubuntu 24.04, matching the hand-built server. The Library is a Red Hat shop: Dataverse runs Rocky Linux 9, staff skills and runbooks are RHEL-family, and the maintainer is preparing for the Red Hat EX294 (RHCE) exam, which tests Ansible against RHEL systems. The rebuild hadn't happened yet, so switching cost almost nothing.

## Decision
Production and local staging run Rocky Linux 10 (official AMIs from the Rocky Enterprise Software Foundation; supported until 2035). The role is Rocky-only. The final Ubuntu version is kept as the git tag `ubuntu-baseline`.

## What changed
- `apt`/`apache2`/`a2enmod` → `dnf`/`httpd`/`conf.d`; certbot from EPEL; its renewal timer enabled explicitly.
- `unattended-upgrades` → `dnf-automatic` (security updates, reboot only when needed).
- SELinux enforcing: all served paths moved under `/var/www` (`/var/www/potree-releases`, `/var/www/acme`) so default labels apply.
- firewalld on, as a second layer behind the security group.
- TLS protocols/ciphers follow the system crypto policy, not per-site overrides.
- Stock `welcome.conf` neutralized (it blocks the directory listing at `/`).
- SSM agent installed by the role (Rocky AMIs don't include it).
- Login user is `rocky`; root filesystem is XFS (`xfs_growfs`, not `resize2fs`).

## What we gave up
Very little for a static site. Ubuntu ships certbot in its main repos (we now depend on EPEL), and its default image includes the SSM agent. Molecule containers can't test SELinux or firewalld, so those are verified on a real host.

## Bonus
Porting from `ubuntu-baseline` to Rocky is a ready-made learning exercise; it touches packages, services, firewall, SELinux and OS differences. The port also found a latent bug in the Ubuntu version: the vhost included `/etc/letsencrypt/options-ssl-apache.conf`, which only exists when certbot's Apache plugin is used, so the first real Let's Encrypt deploy would have failed `configtest`.
