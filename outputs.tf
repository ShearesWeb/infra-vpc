output "nat_instance_id" {
  description = "ID of the NAT instance, null when NAT is disabled"
  value       = var.enable_nat_instance ? aws_instance.nat[0].id : null
}

output "private_zone_id" {
  description = "ID of the private Route53 zone, null when disabled"
  value       = var.enable_private_dns ? aws_route53_zone.private[0].id : null
}

output "private_zone_name" {
  description = "Name of the private Route53 zone, null when disabled"
  value       = var.enable_private_dns ? aws_route53_zone.private[0].name : null
}

output "subnet_ids" {
  description = "Map of environment-tier to list of subnet IDs (e.g. prd-web, com-db)"
  value = {
    for env_tier in distinct([for k, v in local.subnets : "${v.environment}-${v.tier}"]) :
    env_tier => [
      for k, v in local.subnets : aws_subnet.main[k].id
      if "${v.environment}-${v.tier}" == env_tier
    ]
  }
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
