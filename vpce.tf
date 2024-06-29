resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.common.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [
    aws_route_table.app.id,
  ]
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.common.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = [
    aws_route_table.app.id,
  ]
}
