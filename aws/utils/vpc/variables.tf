variable "vpc" {
  type        = string
  description = "The name of the VPC"
}

variable "tags" {
  type        = map(string)
  description = "All the tags to use for searching resources"
}
