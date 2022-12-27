variable "aws_access_key" {
  type        = string
  description = "The AWS access key to be used for authentication"
}

variable "aws_secret_key" {
  type        = string
  description = "The AWS secret key to be used for authentication"
}

variable "aws_region" {
  type        = string
  description = "The AWS region to associate the created resources"
}

variable "ec2_instance_type" {
  type        = string
  description = "The AWS EC2 instance type to use to create the AMI"
}

variable "intermediate_nexus_ami" {
  type        = string
  description = "The name to associate with the intermediate Nexus AMI"
}

variable "ssh_keypair_name" {
  type        = string
  description = "The SSH key pair to associate with EC2 instances"
}

variable "ssh_username" {
  type        = string
  description = "The username to use for the SSH connection"
}

variable "subnet" {
  type        = string
  description = "The subnet ID to use to launch the EC2 instance"
}

variable "vpc" {
  type        = string
  description = "The VPC ID to use to launch the EC2 instance"
}

variable "tags" {
  type        = map(string)
  description = "The tags to associate with resources"
}

variable "tag_prefix" {
  type        = string
  description = "A prefix to add to all tags created"
}

locals {
  ami_name       = "Nexus-Intermediate-AWS-AMI-${timestamp()}"
  files_manifest = jsondecode(file("../config/manifest.json"))
  config_dir     = "../config"
}

data "amazon-ami" "rocky" {
  most_recent = true
  owners      = ["679593333241"]

  filters = {
    name                = "Rocky-8-ec2-202*-*-*.*.x86-64-.*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
    state               = "available"
    architecture        = "x86_64"
  }

}

source "amazon-ebs" "RockyLinux_AMI_Builder_Nexus" {
  access_key      = var.aws_access_key
  ami_description = "Rocky Linux with Nexus OSS 3"
  # AMI names must be between 3 and 128 characters long, and may contain letters, numbers, '(', ')', ',', '.', '-', '/' and '_'
  ami_name                    = replace(local.ami_name, ":", "")
  associate_public_ip_address = "true"
  instance_type               = var.ec2_instance_type
  region                      = var.aws_region
  secret_key                  = var.aws_secret_key
  source_ami                  = data.amazon-ami.rocky.id
  ssh_agent_auth              = true
  ssh_keypair_name            = var.ssh_keypair_name
  ssh_username                = var.ssh_username
  subnet_id                   = var.subnet
  tags                        = merge(var.tags, { "${var.tag_prefix}:createdBy" = "packer" })
  vpc_id                      = var.vpc
}

build {
  sources = ["source.amazon-ebs.RockyLinux_AMI_Builder_Nexus"]

  provisioner "shell" {
    inline = ["sudo dnf update -y", "sudo dnf install ansible awscli -y"]
  }

  provisioner "ansible-local" {
    playbook_file = "../playbooks/packages.yml"
  }

  provisioner "ansible-local" {
    playbook_file = "../playbooks/sysctl.yml"
  }

  provisioner "ansible-local" {
    playbook_file = "../playbooks/hardening.yml"
  }

  // no for_each support by Packer yet... :(
  provisioner "file" {
    destination = "/tmp/${local.files_manifest[0].name}"
    source      = "${local.config_dir}/${local.files_manifest[0].name}"
  }

  provisioner "file" {
    destination = "/tmp/${local.files_manifest[1].name}"
    source      = "${local.config_dir}/${local.files_manifest[1].name}"
  }

  provisioner "file" {
    destination = "/tmp/${local.files_manifest[2].name}"
    source      = "${local.config_dir}/${local.files_manifest[2].name}"
  }

  provisioner "file" {
    destination = "/tmp/${local.files_manifest[3].name}"
    source      = "${local.config_dir}/${local.files_manifest[3].name}"
  }

  provisioner "file" {
    destination = "/tmp/${local.files_manifest[4].name}"
    source      = "${local.config_dir}/${local.files_manifest[4].name}"
  }

  provisioner "shell" {
    inline = [
      "sudo mv -v /tmp/${local.files_manifest[4].name} ${local.files_manifest[4].to}/",
      "sudo mv -v /tmp/${local.files_manifest[3].name} ${local.files_manifest[3].to}/",
      "sudo mv -v /tmp/${local.files_manifest[2].name} ${local.files_manifest[2].to}/",
      "sudo mv -v /tmp/${local.files_manifest[1].name} ${local.files_manifest[1].to}/",
      "sudo mv -v /tmp/${local.files_manifest[0].name} ${local.files_manifest[0].to}/"
    ]
  }

  provisioner "file" {
    destination = "/tmp/"
    source      = "../scripts/basic.sh"
  }

  provisioner "file" {
    destination = "/tmp/"
    source      = "../scripts/restore.sh"
  }

  provisioner "file" {
    destination = "/tmp/"
    source      = "../scripts/backup.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo mv -v /tmp/backup.sh /usr/local/sbin/",
      "sudo mv -v /tmp/restore.sh /usr/local/sbin/",
      "sudo /tmp/basic.sh"
    ]
  }

}
