variable "project_code" {
  description = "The code name of the project used for naming convention."
}

variable "nat_instance_name" {
  description = "The name of the NAT instance"
  type        = string
}

variable "nat_instance_sg_name" {
  description = "The security group name for the NAT instance"
  type        = string
}

variable "allow_traffic_from_nat_instance_sg_name" {
  description = "The security group name allowing traffic from the NAT instance"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the NAT instance will be created"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}
