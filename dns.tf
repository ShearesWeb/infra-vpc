locals {
  private_zone_name = "internal.${var.project_code}"
}

resource "aws_route53_zone" "private_zone" {
  name = local.private_zone_name

  vpc {
    vpc_id     = aws_vpc.common.id
    vpc_region = var.aws_region
  }

  tags = {
    Environment = "com"
    Zone        = "all"
    ProjectCode = var.project_code
    Name        = local.private_zone_name
    VpcId       = aws_vpc.common.id
  }
}
