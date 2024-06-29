provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "com"
      ProjectCode = var.project_code
    }
  }
}

terraform {
  required_version = ">=1.4.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.31.0"
    }
  }

  backend "s3" {
    bucket               = "com-all-bucket-tfstate-algebananazzzzz"
    key                  = "comvpcsg.tfstate"
    workspace_key_prefix = "tf-state"
    region               = "ap-southeast-1"
  }
}
