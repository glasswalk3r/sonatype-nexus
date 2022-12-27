output "security_groups" {
  description = "All security groups ID's to associated with Nexus EC2 instance"
  value       = [data.aws_security_group.nexus.id]
}
