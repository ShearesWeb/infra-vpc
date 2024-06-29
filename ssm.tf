resource "aws_ssm_parameter" "vpc_id" {
  name  = "/${local.vpc_name}/id"
  type  = "String"
  value = aws_vpc.common.id
}

resource "aws_ssm_parameter" "internal_dns_id" {
  name  = "/${local.vpc_name}/internal_dns/zone_id"
  type  = "String"
  value = aws_route53_zone.private_zone.id
}

resource "aws_ssm_parameter" "internal_dns_name" {
  name  = "/${local.vpc_name}/internal_dns/zone_name"
  type  = "String"
  value = aws_route53_zone.private_zone.name
}

resource "aws_ssm_parameter" "web_subnets" {
  for_each    = local.web_subnet_configuration
  name        = "/${local.vpc_name}/${each.value.env}/web/${each.value.availability_zone}/id"
  description = "Id of subnet ${each.key}"
  type        = "String"
  value       = aws_subnet.web[each.key].id

  tags = {
    Environment = each.value.env
    Name        = each.key
    Zone        = "web"
    ProjectCode = var.project_code
    SubnetType  = "public"
  }
}

resource "aws_ssm_parameter" "app_subnets" {
  for_each    = local.app_subnet_configuration
  name        = "/${local.vpc_name}/${each.value.env}/app/${each.value.availability_zone}/id"
  description = "Id of subnet ${each.key}"
  type        = "String"
  value       = aws_subnet.app[each.key].id

  tags = {
    Environment = each.value.env
    Name        = each.key
    Zone        = "app"
    ProjectCode = var.project_code
    SubnetType  = "private"
  }
}

resource "aws_ssm_parameter" "db_subnets" {
  for_each    = local.db_subnet_configuration
  name        = "/${local.vpc_name}/${each.value.env}/db/${each.value.availability_zone}/id"
  description = "Id of subnet ${each.key}"
  type        = "String"
  value       = aws_subnet.db[each.key].id

  tags = {
    Environment = each.value.env
    Name        = each.key
    Zone        = "db"
    ProjectCode = var.project_code
    SubnetType  = "private"
  }
}
