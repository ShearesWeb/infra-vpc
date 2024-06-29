locals {
  nat_instance_name                       = "com-web-ec2inst-natinstance"
  nat_instance_sg_name                    = "com-web-sg-natingress"
  allow_traffic_from_nat_instance_sg_name = "com-app-sg-allownat"
  nat_instance_ssh_key_name               = "com-web-keypair-sshec2instances"
  nat_instance_subnet_name                = "com-web-subnet-public-1a"
}

module "nat_instance" {
  source                                  = "./modules/natinstance"
  project_code                            = var.project_code
  vpc_id                                  = aws_vpc.common.id
  vpc_cidr_block                          = aws_vpc.common.cidr_block
  subnet_id                               = aws_subnet.web[local.nat_instance_subnet_name].id
  nat_instance_name                       = local.nat_instance_name
  nat_instance_sg_name                    = local.nat_instance_sg_name
  allow_traffic_from_nat_instance_sg_name = local.allow_traffic_from_nat_instance_sg_name
}

resource "aws_ec2_instance_connect_endpoint" "instance_connect" {
  subnet_id          = aws_subnet.web[local.nat_instance_subnet_name].id
  security_group_ids = [module.nat_instance.nat_instance_sg_id]
}

