resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = local.private_route_table_ids

  tags = {
    Name = "${var.project_code}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = local.private_route_table_ids

  tags = {
    Name = "${var.project_code}-dynamodb-endpoint"
  }
}

resource "aws_ec2_instance_connect_endpoint" "main" {
  count = var.enable_vpc_endpoints ? 1 : 0

  subnet_id          = aws_subnet.main[local.primary_public_subnet_key].id
  security_group_ids = var.enable_nat_instance ? [aws_security_group.nat[0].id] : []

  tags = {
    Name = "${var.project_code}-eice"
  }
}
