variable "aws_region" {}

provider "aws" {
  region = var.aws_region
}

//provider "template" {}

terraform {
  backend "s3" {}
}
