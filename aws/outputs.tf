output "environment" {
  value       = var.environment
  description = "The environment name"
}

output "project_name" {
  value       = var.project
  description = "The name of the project"
}

output "security_group" {
  description = "The name of the security group created for EC2 instances"
  value       = aws_security_group.nexus.name
}

output "vpc_id" {
  description = "The ID of the main VPC used"
  value       = module.search_vpc.vpc_id
}

output "s3_backup_arn" {
  description = "The S3 bucket ARN used for Nexus's backups"
  value       = aws_s3_bucket.backup.arn
}

output "s3_backup_uri" {
  description = "The S3 URI to access with awscli"
  value       = "s3://${aws_s3_bucket.backup.bucket}"
}
