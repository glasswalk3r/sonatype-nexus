variable "vpc_id" {
  type        = string
  description = "The ID of the VPC the security group is associated with"
}

variable "tags" {
  type        = map(string)
  description = "All the tags to use for searching"
}

variable "project_name" {
  type        = string
  description = "The name of the project the security group is associated with"
}
