# Cutover from the hand-built server

One-time plan to replace `Potree-computing` (`i-0cbaff2d7178c6cd6`, Ubuntu 22.04, t2.large, configured by hand since 2023) with a server built from this repo. Delete this file once the old instance is terminated.

The public IP is an Elastic IP (`44.225.161.146`), so cutover and rollback are both "move the IP". Campus DNS does not change.

## Before

- [ ] `content/collections/` matches the live server. Re-sync right before cutover in case someone uploaded something:
      `rsync -avn -e "ssh -i ~/.ssh/potree-test.pem" ubuntu@pointcloud.ucla.edu:/home/ubuntu/potree/<Name>/ content/collections/<Name>/` (drop `-n` to copy)
- [ ] `pixi run test` passes.
- [ ] `terraform/terraform.tfvars` exists with your `admin_ssh_cidrs` and `eip_target = "legacy"`.
- [ ] Pick a quiet time. Expect a minute or two of certificate warnings (see step 5).

## Steps

1. **Build the new server.** `pixi run tf-init && pixi run tf-plan`. Expect: new instance, security group, IAM role; the Elastic IP imported; an association to the legacy instance (no change in behavior). Then `pixi run tf-apply`.
2. **Configure it with a self-signed cert first.** `cd ansible && pixi run -- ansible-playbook playbooks/site.yml -e potree_tls_mode=selfsigned`
3. **Test it under the real hostname, without DNS:**
   `pixi run -- terraform -chdir=terraform output -raw test_before_cutover | sh`
   Also point a browser at it: add `<new-ip> www.pointcloud.ucla.edu` to `/etc/hosts`, click through collections, then remove the line.
4. **Move the IP.** Set `eip_target = "new"` in terraform.tfvars, `pixi run tf-apply`.
5. **Get the real certificate.** `pixi run deploy`. With the IP now pointing at the new server, certbot completes the HTTP-01 challenge and Apache switches to the Let's Encrypt cert.
6. **Verify.** `pixi run site-check`, and check a few collections in a browser.

## Rollback

Set `eip_target = "legacy"`, `pixi run tf-apply`. The old server is untouched and still has a valid cert until 2026-12-01.

## After (two weeks of clean Site watch runs)

- [ ] Stop the legacy instance; a week later, terminate it. Keep snapshot `snap-0f127586cb7bdaa55` for 90 days.
- [ ] Decide on the unattached volume `vol-0306e2a8b1c5553a1` (8 GB, created 2026-04-14, purpose unknown).
- [ ] Remove the `potree-test` security group (it allows SSH and 8080 from anywhere) and the `potree-test2-to-s3-bucket` instance profile if nothing else uses them.
- [ ] Remove `legacy_instance_id` and the `"legacy"` option from Terraform.
- [ ] Consider turning on HSTS (`potree_hsts_max_age: 31536000`).
- [ ] Delete this file.
