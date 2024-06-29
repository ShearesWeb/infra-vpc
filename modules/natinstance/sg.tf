
resource "aws_security_group" "ingress" {
  name        = var.nat_instance_sg_name
  vpc_id      = var.vpc_id
  description = "Allow inbound HTTP/HTTPS traffic from private subnets to nat instance"

  ingress {
    description = "Allow inbound HTTP traffic from servers in the private subnet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Allow inbound HTTPS traffic from servers in the private subnet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Allow inbound ICMP diagnostics from servers in the private subnet"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr_block]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Environment    = "com"
    Name           = var.nat_instance_sg_name
    Zone           = "web"
    ProjectCode    = var.project_code
    TargetResource = var.nat_instance_name
  }
}

resource "aws_security_group" "egress" {
  name        = var.allow_traffic_from_nat_instance_sg_name
  vpc_id      = var.vpc_id
  description = "Allow inbound HTTP/HTTPS traffic from nat instance"

  ingress {
    description     = "Allow inbound HTTP traffic from nat instance"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ingress.id]
  }

  ingress {
    description     = "Allow inbound HTTPS traffic from nat instance"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ingress.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Environment = "com"
    Name        = var.allow_traffic_from_nat_instance_sg_name
    Zone        = "app"
    ProjectCode = var.project_code
  }
}
