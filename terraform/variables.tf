variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-west-2"
}

variable "rocky_major_version" {
  description = "Rocky Linux major version (10 is supported until 2035)."
  type        = number
  default     = 10
}

variable "instance_type" {
  description = "EC2 instance type. Graviton (t4g) is cheapest for a static site; the AMI architecture follows it."
  type        = string
  default     = "t4g.small"
}

variable "root_volume_gb" {
  description = "Root volume size (XFS on Rocky). The legacy 8 GB disk filled up and broke cert renewal in 2026."
  type        = number
  default     = 30
}

variable "subnet_id" {
  description = "Subnet for the web server (default VPC, us-west-2a, same as the legacy host)."
  type        = string
  default     = "subnet-27c2d75e"
}

variable "key_name" {
  description = "Existing EC2 key pair for SSH (Ansible, user rocky). SSM Session Manager works as a fallback once Ansible has installed the agent."
  type        = string
  default     = "potree-test"
}

variable "admin_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH in. Keep this tight; SSM is the break-glass path."
  type        = list(string)

  validation {
    condition     = length(var.admin_ssh_cidrs) > 0 && !contains(var.admin_ssh_cidrs, "0.0.0.0/0")
    error_message = "List at least one admin CIDR, and do not open SSH to the whole internet."
  }
}

variable "eip_allocation_id" {
  description = "The existing Elastic IP that pointcloud.ucla.edu resolves to (44.225.161.146). Imported, never recreated."
  type        = string
  default     = "eipalloc-06b86fbafa7bd68db"
}

variable "legacy_instance_id" {
  description = "The hand-built server being replaced. Only used while eip_target = \"legacy\"."
  type        = string
  default     = "i-0cbaff2d7178c6cd6"
}

variable "eip_target" {
  description = "Which server the public IP points at. Cutover and rollback are a one-word change here."
  type        = string
  default     = "legacy"

  validation {
    condition     = contains(["legacy", "new"], var.eip_target)
    error_message = "eip_target must be \"legacy\" or \"new\"."
  }
}
