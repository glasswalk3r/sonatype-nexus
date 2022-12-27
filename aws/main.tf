locals {
  basic = {
    ssh_keypair_name       = var.ssh_key_pair
    ssh_username           = var.packer_ssh_username
    ec2_instance_type      = var.ec2_instance_type
    intermediate_nexus_ami = var.intermediate_nexus
  }
  tags = {
    "${var.tag_prefix}:Environment"   = var.environment,
    "${var.tag_prefix}:Owner"         = var.owner,
    "${var.tag_prefix}:GitRepository" = var.git_repository,
    "${var.tag_prefix}:Project"       = var.project
  }
  # always put the local.basic last to overwrite anything necessary
  content = jsonencode(merge(local.tags, local.basic))
}

resource "local_file" "packer" {
  content         = local.content
  filename        = "${path.module}/packer_cfg.pkrvars.json"
  file_permission = "0660"
}

module "search_vpc" {
  source = "./utils/vpc"
  vpc    = var.nexus_vpc
  tags   = local.tags
}

resource "aws_security_group" "nexus" {
  vpc_id      = module.search_vpc.vpc_id
  name        = var.project
  description = var.short_desc

  dynamic "ingress" {
    for_each = var.allowed_cidrs_for_ssh
    content {
      from_port   = var.ssh_port
      to_port     = var.ssh_port
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr
      description = "SSH from ${ingress.value.name}"
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_cidrs_for_https
    content {
      from_port   = var.server_port
      to_port     = var.server_port
      protocol    = "tcp"
      cidr_blocks = ingress.value.value
      description = "HTTP from ${ingress.value.name}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
}

resource "aws_s3_bucket" "backup" {
  bucket        = var.nexus_backup_bucket
  force_destroy = false
}

resource "aws_s3_bucket_acl" "backup" {
  bucket = aws_s3_bucket.backup.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    id     = "expires"
    status = "Enabled"
    expiration {
      days = var.backup_expiration
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
