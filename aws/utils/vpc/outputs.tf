output "vpc_id" {
  description = "The ID of the main VPC"
  value       = data.aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The main VPC CIDR block"
  value       = data.aws_vpc.main.cidr_block
}
