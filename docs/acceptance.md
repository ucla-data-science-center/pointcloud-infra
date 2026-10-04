# Real-host acceptance checklist

Local staging (a container) can't exercise SELinux, firewalld, reboots, the SSM agent, or real certificate renewal. Run this on any new production host before it takes traffic, and after major OS upgrades. Record the date and result in the PR or hub note.

Replace `<host>` with the instance IP (before cutover) or `www.pointcloud.ucla.edu` (after).

## Configuration
- [ ] `pixi run deploy-check` reports no changes right after `pixi run deploy` (idempotent on the real host).
- [ ] `ssh rocky@<host> 'getenforce'` prints `Enforcing`.
- [ ] `ssh rocky@<host> 'sudo ausearch -m avc -ts boot'` shows no httpd denials after browsing a few collections.
- [ ] `ssh rocky@<host> 'ls -Z /var/www/pointcloud-releases/*/Iceland | head -3'` shows `httpd_sys_content_t`.
- [ ] `ssh rocky@<host> 'sudo firewall-cmd --get-active-zones; sudo firewall-cmd --list-services'` shows the interface in a zone that allows `http`, `https`, `ssh`.

## TLS
- [ ] `ssh rocky@<host> 'sudo certbot certificates'` lists `www.pointcloud.ucla.edu` covering both names.
- [ ] `ssh rocky@<host> 'grep -E "authenticator|webroot_path|installer" /etc/letsencrypt/renewal/www.pointcloud.ucla.edu.conf'` shows `webroot` and `/var/www/acme`, no `installer`.
- [ ] After the IP points here: `ssh rocky@<host> 'sudo certbot renew --dry-run'` succeeds.
- [ ] `ssh rocky@<host> 'systemctl is-enabled certbot-renew.timer'` prints `enabled`.

## Access
- [ ] Session Manager works without SSH: `aws ssm start-session --profile ucla-library-dsc --region us-west-2 --target <instance-id>`.

## Updates and reboot
- [ ] `ssh rocky@<host> 'systemctl is-enabled dnf-automatic.timer; grep -E "^(upgrade_type|apply_updates|reboot) " /etc/dnf/automatic.conf'` shows the timer enabled and `security` / `yes` / `when-needed`.
- [ ] Reboot (`ssh rocky@<host> 'sudo systemctl reboot'`), wait two minutes, then `pixi run site-check` (or the `curl --resolve` command from `terraform output test_before_cutover` before cutover) passes, and `getenforce` is still `Enforcing`.

## The site
- [ ] In a browser, open three collections (one simple, one with multiple clouds, one with annotations) and confirm the point clouds render.
- [ ] `pixi run site-check` passes (after cutover).
