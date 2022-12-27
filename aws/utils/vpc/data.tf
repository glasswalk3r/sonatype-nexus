data "aws_vpc" "main" {
  state = "available"
  tags  = var.tags
}

