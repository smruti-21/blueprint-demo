variable "aws_region" {}

provider "aws" {
  region = "eu-west-1"
//  profile = "toolchain"
}

terraform {
  backend "s3" {}
}
