locals {
  web_rtb_name = "com-web-rtb-${var.project_code}"
  app_rtb_name = "com-app-rtb-${var.project_code}"
  db_rtb_name  = "com-db-rtb-${var.project_code}"
}

resource "aws_main_route_table_association" "default" {
  vpc_id         = aws_vpc.common.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table" "web" {
  vpc_id = aws_vpc.common.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = {
    Environment = "com"
    Zone        = "web"
    Name        = local.web_rtb_name
    ProjectCode = var.project_code
    SubnetType  = "public"
  }
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.common.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.nat_instance.primary_network_interface_id
  }

  route {
    ipv6_cidr_block      = "::/0"
    network_interface_id = module.nat_instance.primary_network_interface_id
  }

  tags = {
    Environment = "com"
    Zone        = "app"
    Name        = local.app_rtb_name
    ProjectCode = var.project_code
    SubnetType  = "private"
  }

  depends_on = [
    module.nat_instance
  ]
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.common.id

  tags = {
    Environment = "com"
    Zone        = "db"
    Name        = local.db_rtb_name
    ProjectCode = var.project_code
    SubnetType  = "private"
  }
}
