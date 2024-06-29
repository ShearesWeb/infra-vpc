resource "aws_instance" "nat" {
  instance_type   = "t3.micro"
  ami             = data.aws_ami.nat.id
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.ingress.id]

  associate_public_ip_address = true
  source_dest_check           = false

  tags = {
    Environment = "com"
    Name        = var.nat_instance_name
    Zone        = "web"
    ProjectCode = var.project_code
  }

  lifecycle {
    ignore_changes = [security_groups]
  }
}
