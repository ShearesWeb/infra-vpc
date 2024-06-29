locals {
  vpc_cidr_block = "10.0.0.0/16"
  vpc_name       = "com-all-vpc-${var.project_code}"
  igw_name       = "com-all-igw-${var.project_code}"
}

resource "aws_vpc" "common" {
  cidr_block           = local.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = "com"
    Name        = local.vpc_name
    Zone        = "all"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.common.id

  tags = {
    Environment = "com"
    Name        = local.igw_name
    Zone        = "web"
  }
}
