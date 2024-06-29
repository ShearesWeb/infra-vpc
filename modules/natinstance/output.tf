output "primary_network_interface_id" {
  value = aws_instance.nat.primary_network_interface_id
}

output "nat_instance_sg_id" {
  value = aws_security_group.ingress.id
}

output "nat_instance_sg_name" {
  value = aws_security_group.ingress.name
}

output "allow_from_nat_instance_sg_name" {
  value = aws_security_group.egress.name
}

output "allow_from_nat_instance_sg_id" {
  value = aws_security_group.egress.id
}
