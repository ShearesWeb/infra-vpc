resource "aws_security_group" "nat" {
  count = var.enable_nat_instance ? 1 : 0

  name        = "${var.project_code}-nat-sg"
  description = "Allow all traffic from VPC to NAT instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_code}-nat-sg"
  }
}

resource "aws_instance" "nat" {
  count = var.enable_nat_instance ? 1 : 0

  ami                         = data.aws_ami.fck_nat[0].id
  instance_type               = var.nat_instance_type
  subnet_id                   = aws_subnet.main[local.primary_public_subnet_key].id
  vpc_security_group_ids      = [aws_security_group.nat[0].id]
  associate_public_ip_address = true
  source_dest_check           = false

  tags = {
    Name = "${var.project_code}-nat"
  }
}
