<!-- BEGIN_TF_DOCS -->
# nexus

Nexus implementation on EC2.

## Features

- an Rocky Linux based AWS AMI, with Nexus installed and configured
- a private S3 bucket to manage Nexus backups
- an AWS ALB for external access to Nexus
- security group configuration based on parameters to limit access to Nexus
- hardening configuration on Rocky Linux
- a VM based on Rocky Linux for local testing

## How to setup it

You will need:

1. the GNU make program to run the setup. Check the `Makefile` file for details.
2. [Terraform](https://terraform.io), see the file `versions.tf` for details.
3. [Packer](https://packer.io) 1.8.5 or higher
4. Bash version 4 or higher
5. [terraform-docs](https://terraform-docs.io/user-guide/introduction/) version
v0.16.0 or higher

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

### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 4.48.0 |
| <a name="requirement_http"></a> [http](#requirement\_http) | 3.2.1 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_amazon-ami"></a> [amazon-ami](#provider\_amazon-ami) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.48.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.2.3 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_search_vpc"></a> [search\_vpc](#module\_search\_vpc) | ./utils/vpc | n/a |

### Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.backup](https://registry.terraform.io/providers/hashicorp/aws/4.48.0/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.backup](https://registry.terraform.io/providers/hashicorp/aws/4.48.0/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_lifecycle_configuration.backup](https://registry.terraform.io/providers/hashicorp/aws/4.48.0/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.backup](https://registry.terraform.io/providers/hashicorp/aws/4.48.0/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_security_group.nexus](https://registry.terraform.io/providers/hashicorp/aws/4.48.0/docs/resources/security_group) | resource |
| [local_file.packer](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [amazon-ami_amazon-ami.rocky](https://registry.terraform.io/providers/hashicorp/amazon-ami/latest/docs/data-sources/amazon-ami) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidrs_for_https"></a> [allowed\_cidrs\_for\_https](#input\_allowed\_cidrs\_for\_https) | A list of CIDRs to allow HTTPS access to Nexus | `list(object({ name = string, cidr = string }))` | n/a | yes |
| <a name="input_allowed_cidrs_for_ssh"></a> [allowed\_cidrs\_for\_ssh](#input\_allowed\_cidrs\_for\_ssh) | A list of CIDRs to allow SSH access to Nexus | `list(object({ name = string, cidr = string }))` | n/a | yes |
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | The AWS access key to be used for authentication | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to associate the created resources | `string` | n/a | yes |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | The AWS secret key to be used for authentication | `string` | n/a | yes |
| <a name="input_backup_expiration"></a> [backup\_expiration](#input\_backup\_expiration) | The number days a backup file age is considered to expire and be removed | `number` | n/a | yes |
| <a name="input_ec2_instance_type"></a> [ec2\_instance\_type](#input\_ec2\_instance\_type) | The EC2 instance type to use | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment everything will be deployed to. Use as a tag. | `string` | n/a | yes |
| <a name="input_git_repository"></a> [git\_repository](#input\_git\_repository) | The URL to the git repository. Used as a tag | `string` | n/a | yes |
| <a name="input_intermediate_nexus"></a> [intermediate\_nexus](#input\_intermediate\_nexus) | The name of the intermediate nexus resources (AMI and EC2 instance) | `string` | n/a | yes |
| <a name="input_intermediate_nexus_ami"></a> [intermediate\_nexus\_ami](#input\_intermediate\_nexus\_ami) | The name to associate with the intermediate Nexus AMI | `string` | n/a | yes |
| <a name="input_nexus_backup_bucket"></a> [nexus\_backup\_bucket](#input\_nexus\_backup\_bucket) | The name of the S3 bucket that will be used for Nexus backup storage | `string` | n/a | yes |
| <a name="input_nexus_vpc"></a> [nexus\_vpc](#input\_nexus\_vpc) | The name of the VPC where Nexus instance will be created | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | The name of the owner of the resources. Used as a tag | `string` | n/a | yes |
| <a name="input_packer_ssh_username"></a> [packer\_ssh\_username](#input\_packer\_ssh\_username) | The username for Packer to connect to EC2 instance | `string` | `"rocky"` | no |
| <a name="input_project"></a> [project](#input\_project) | The name of the project the resources will be part of | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The name of the AWS region | `string` | n/a | yes |
| <a name="input_server_port"></a> [server\_port](#input\_server\_port) | The port Nexus server will listen to | `number` | n/a | yes |
| <a name="input_short_desc"></a> [short\_desc](#input\_short\_desc) | A short description for this module | `string` | `"Nexus implementation on EC2."` | no |
| <a name="input_ssh_key_pair"></a> [ssh\_key\_pair](#input\_ssh\_key\_pair) | The name of the SSH key pair to associate with EC2 instances | `string` | n/a | yes |
| <a name="input_ssh_keypair_name"></a> [ssh\_keypair\_name](#input\_ssh\_keypair\_name) | The SSH key pair to associate with EC2 instances | `string` | n/a | yes |
| <a name="input_ssh_port"></a> [ssh\_port](#input\_ssh\_port) | The port the SSH server will listen to | `number` | `22` | no |
| <a name="input_ssh_username"></a> [ssh\_username](#input\_ssh\_username) | The username to use for the SSH connection | `string` | n/a | yes |
| <a name="input_subnet"></a> [subnet](#input\_subnet) | The subnet ID to use to launch the EC2 instance | `string` | n/a | yes |
| <a name="input_tag_prefix"></a> [tag\_prefix](#input\_tag\_prefix) | A prefix to add to all tags created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to associate with resources | `map(string)` | n/a | yes |
| <a name="input_vpc"></a> [vpc](#input\_vpc) | The VPC ID to use to launch the EC2 instance | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_environment"></a> [environment](#output\_environment) | The environment name |
| <a name="output_project_name"></a> [project\_name](#output\_project\_name) | The name of the project |
| <a name="output_s3_backup_arn"></a> [s3\_backup\_arn](#output\_s3\_backup\_arn) | The S3 bucket ARN used for Nexus's backups |
| <a name="output_s3_backup_uri"></a> [s3\_backup\_uri](#output\_s3\_backup\_uri) | The S3 URI to access with awscli |
| <a name="output_security_group"></a> [security\_group](#output\_security\_group) | The name of the security group created for EC2 instances |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the main VPC used |
<!-- END_TF_DOCS -->