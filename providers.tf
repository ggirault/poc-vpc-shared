terraform {
  required_version = ">= 0.14.0"

  backend "s3" {
    encrypt = true
    region         = "eu-west-3"
    bucket         = "archsol-tfsates-eu-west-3"
    # dynamodb_table = ""
    profile        = "archsol"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}


provider "aws" {
  region  = "eu-west-3"
  profile = "archsol"
  default_tags {
    tags = {
      owner       = "architecte"
      environment = "archsol"
    }
  }
}
