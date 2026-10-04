# -----------------------------------------------------------------------------
# Image: latest official Rocky Linux AMI (published by the Rocky Enterprise
# Software Foundation's AWS account) for the instance type's architecture.
# Instances ignore AMI drift so a new point release never forces a rebuild;
# patching is dnf-automatic's job (see the Ansible role).
# -----------------------------------------------------------------------------
data "aws_ec2_instance_type" "web" {
  instance_type = var.instance_type
}

locals {
  rocky_arch = contains(data.aws_ec2_instance_type.web.supported_architectures, "arm64") ? "aarch64" : "x86_64"
}

data "aws_ami" "rocky" {
  owners      = ["792107900819"] # Rocky Enterprise Software Foundation
  most_recent = true

  filter {
    name   = "name"
    values = ["Rocky-${var.rocky_major_version}-EC2-Base-${var.rocky_major_version}.*.${local.rocky_arch}"]
  }

  filter {
    name   = "architecture"
    values = [local.rocky_arch == "aarch64" ? "arm64" : "x86_64"]
  }
}

data "aws_subnet" "web" {
  id = var.subnet_id
}

# -----------------------------------------------------------------------------
# Network access: web open to all, SSH only from admin CIDRs.
# -----------------------------------------------------------------------------
resource "aws_security_group" "web" {
  name        = "pointcloud-web"
  description = "pointcloud.ucla.edu web server"
  vpc_id      = data.aws_subnet.web.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP (redirects to HTTPS, ACME challenges)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = toset(var.admin_ssh_cidrs)

  security_group_id = aws_security_group.web.id
  description       = "SSH from admin network"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.web.id
  description       = "Outbound (apt, Let's Encrypt, GitHub releases)"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# -----------------------------------------------------------------------------
# Instance role: SSM Session Manager only, as a no-SSH fallback shell.
# The site itself needs no AWS access (browsers load point clouds from S3).
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "web" {
  name               = "pointcloud-web"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.web.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web" {
  name = "pointcloud-web"
  role = aws_iam_role.web.name
}

# -----------------------------------------------------------------------------
# The web server. Configuration is Ansible's job; Terraform only builds the box.
# -----------------------------------------------------------------------------
resource "aws_instance" "web" {
  ami                    = data.aws_ami.rocky.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name

  # Temporary public IP for configuring and testing before the Elastic IP moves.
  associate_public_ip_address = true

  metadata_options {
    http_tokens   = "required" # IMDSv2 only
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_gb
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "pointcloud-web-production"
    Role = "web"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# -----------------------------------------------------------------------------
# Public IP. The existing Elastic IP is adopted (imported), protected from
# deletion, and pointed at whichever server var.eip_target names.
# -----------------------------------------------------------------------------
import {
  to = aws_eip.public
  id = var.eip_allocation_id
}

resource "aws_eip" "public" {
  domain = "vpc"

  tags = {
    Name = "pointcloud-public"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_eip_association" "public" {
  allocation_id       = aws_eip.public.id
  instance_id         = var.eip_target == "new" ? aws_instance.web.id : var.legacy_instance_id
  allow_reassociation = true
}

# -----------------------------------------------------------------------------
# Plan-time health check: warns (does not fail) if the live site is down.
# -----------------------------------------------------------------------------
check "site_up" {
  data "http" "site" {
    url = "https://www.pointcloud.ucla.edu/"
  }

  assert {
    condition     = data.http.site.status_code == 200
    error_message = "https://www.pointcloud.ucla.edu/ returned ${data.http.site.status_code}, expected 200."
  }
}
