output "private_zone_id" {
  value = aws_route53_zone.private_zone.id
}

output "private_zone_name" {
  value = aws_route53_zone.private_zone.name
}
