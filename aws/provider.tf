provider "aws" {
  region = var.region
  default_tags {
    tags = local.tags
  }
}

terraform {
  backend "local" {}
}
