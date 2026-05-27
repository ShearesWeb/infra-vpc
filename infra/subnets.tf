resource "aws_subnet" "main" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name             = "${var.project_code}-${each.key}"
    Environment      = each.value.environment
    Zone             = each.value.tier
    SubnetType       = each.value.subnet_type
    AvailabilityZone = each.value.az_short
  }
}
