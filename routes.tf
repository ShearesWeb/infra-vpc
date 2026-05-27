resource "aws_route_table" "web" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_code}-web-rtb"
  }
}

resource "aws_route_table" "app" {
  count = var.enable_nat_instance ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat[0].primary_network_interface_id
  }

  tags = {
    Name = "${var.project_code}-app-rtb"
  }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_code}-db-rtb"
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "web" {
  for_each = local.web_subnets

  route_table_id = aws_route_table.web.id
  subnet_id      = aws_subnet.main[each.key].id
}

resource "aws_route_table_association" "app" {
  for_each = local.app_subnets

  route_table_id = aws_route_table.app[0].id
  subnet_id      = aws_subnet.main[each.key].id
}

resource "aws_route_table_association" "db" {
  for_each = local.db_subnets

  route_table_id = aws_route_table.db.id
  subnet_id      = aws_subnet.main[each.key].id
}
