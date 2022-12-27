# nexus

Nexus implementation on EC2.

## Features

- an Rocky Linux based AWS AMI, with Nexus installed and configured
- a private S3 bucket to manage Nexus backups
- an AWS ALB for external access to Nexus
- security group configuration based on parameters to limit access to Nexus
- hardening configuration on Rocky Linux
- a Vagrant based VM with Rocky Linux for local testing

## How to setup it

You will need:

1. the GNU make program to run the setup. Check the `Makefile` file for details.
2. [Terraform](https://terraform.io), see the file `versions.tf` for details.
3. [Packer](https://packer.io) 1.8.5 or higher
4. Bash version 4 or higher
5. [terraform-docs](https://terraform-docs.io/user-guide/introduction/) version
v0.16.0 or higher
6. [aws-cli](https://aws.amazon.com/cli/) version 2.1.30 or higher
7. [Vagrant](https://vagrantup.com) version 2.3.4, but only for local testing

## How to use it

Export the expected environment variables for the awscli, as documented
[here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
.

Packer image generation **is not** idempotent.

This project is built in different phases:

1. Uses Packer to build an image based on the latest available AMI for Rocky Linux.
This image will include the latest Nexus release, tools for troubleshooting and
RPM packages updates. OS hardening is applied too. The `Makefile` targets for
this step are:
  1. `make packer-cfg`
  2. `make packer-build` (this will execute `packer-cfg` by default)
2. The previous image is used to create an EC2 instance. After booting it up,
it is required to execute all manual steps that cannot be automated (
authorization management, credentials, etc). The byproduct
here is another AMI. See the `intermediate` target on the `Makefile`.
3. A third instance is booted with Terraform, using the previous intermediate
AMI image. See the `final` target on the `Makefile`.

After everything is tested, you can use `make clean` to remove the intermediate
EC2 instance and the related intermediate AMI.

The setup tries to reuse scripts and configuration used for the Vagrant
implementation, which includes shell scripts, configuration files and Ansible
playbooks.

You should also check the `README.md` file at the parent directory from here.

### Configuration

For initial configuration, provide a `terraform.tfvars` file in the same
directory this README is located, with a content like the example below:

```
region             = "us-east-1"
environment        = "development"
project_name       = "nexus"
nexus_vpc          = "default"
intermediate_nexus = "intermediate_nexus"
ec2_instance_type  = "t2.medium"
server_port        = 8081
ssh_key_pair       = "default"
tag_prefix         = "alceu"
git_repository     = "github.com/glasswalk3r/sonatype-nexus"
owner              = "alceu"
project            = "Sonatype Nexus"
```

For further explanation, be sure to check the next section.

## Terraform

