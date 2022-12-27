data "aws_security_group" "nexus" {
  name   = var.project_name
  vpc_id = var.vpc_id
  tags   = var.tags
}
