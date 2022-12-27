variable "backup_expiration" {
  type        = number
  description = "The number days a backup file age is considered to expire and be removed"
}

variable "allowed_cidrs_for_ssh" {
  type        = list(object({ name = string, cidr = string }))
  description = "A list of CIDRs to allow SSH access to Nexus"
}

variable "allowed_cidrs_for_https" {
  type        = list(object({ name = string, cidr = string }))
  description = "A list of CIDRs to allow HTTPS access to Nexus"
}

variable "region" {
  type        = string
  description = "The name of the AWS region"
}

variable "short_desc" {
  type        = string
  description = "A short description for this module"
  default     = "Nexus implementation on EC2."
}

variable "server_port" {
  type        = number
  description = "The port Nexus server will listen to"
}

variable "ssh_port" {
  type        = number
  description = "The port the SSH server will listen to"
  default     = 22
}

variable "intermediate_nexus" {
  type        = string
  description = "The name of the intermediate nexus resources (AMI and EC2 instance)"
}

variable "nexus_vpc" {
  type        = string
  description = "The name of the VPC where Nexus instance will be created"
}

variable "packer_ssh_username" {
  type        = string
  description = "The username for Packer to connect to EC2 instance"
  default     = "rocky"
}

variable "ec2_instance_type" {
  type        = string
  description = "The EC2 instance type to use"
}

variable "ssh_key_pair" {
  type        = string
  description = "The name of the SSH key pair to associate with EC2 instances"
}

variable "tag_prefix" {
  type        = string
  description = "A prefix to add to all tags created"
}

variable "environment" {
  type        = string
  description = "The name of the environment everything will be deployed to. Use as a tag."
}

variable "git_repository" {
  type        = string
  description = "The URL to the git repository. Used as a tag"
}

variable "owner" {
  type        = string
  description = "The name of the owner of the resources. Used as a tag"
}

variable "project" {
  type        = string
  description = "The name of the project the resources will be part of"
}

variable "nexus_backup_bucket" {
  type        = string
  description = "The name of the S3 bucket that will be used for Nexus backup storage"
}
