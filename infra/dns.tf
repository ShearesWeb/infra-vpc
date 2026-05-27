resource "aws_route53_zone" "private" {
  count = var.enable_private_dns ? 1 : 0

  name = "internal.${var.project_code}"

  vpc {
    vpc_id     = aws_vpc.main.id
    vpc_region = var.aws_region
  }

  tags = {
    Name = "internal.${var.project_code}"
  }
}
