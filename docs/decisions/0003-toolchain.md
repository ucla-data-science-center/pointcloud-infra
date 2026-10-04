# 0003: One repo, pixi for tooling, S3-native Terraform locking

Date: 2026-10-04 · Status: accepted

## Decision
- **One repo** for Terraform, Ansible, and content. Dataverse splits these across repos; this project is small enough that one PR should be able to change a page, its Apache config, and the security group together.
- **pixi** installs every tool (Ansible, Molecule, Terraform, tflint, linters) at locked versions from conda-forge. Setup is `pixi install`. This follows the DSC default for Python tooling; dataverse-ansible uses uv + pyproject, which works too but does not cover Terraform.
- **Terraform S3 backend with `use_lockfile = true`** (Terraform 1.10+). State locks live next to the state in S3, so there is no DynamoDB table. Same bucket as Dataverse (`ucla-library-terraform-state`), separate key.
- **Molecule with the Podman driver.** Rootless, no Docker Desktop license, same driver locally and in GitHub Actions.
- **Dynamic inventory** (`amazon.aws.aws_ec2`) finds the server by tag, so an instance rebuild never requires editing an IP.
- **Role argument specs** (`meta/argument_specs.yml`) validate variables before the role runs.

## Consequences
- Contributors install pixi and Podman, nothing else.
- Moving to OpenTofu later is easy (also on conda-forge); nothing here depends on Terraform-only features.
