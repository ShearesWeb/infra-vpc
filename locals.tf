locals {
  tier_index = {
    web = 0
    app = 1
    db  = 2
  }

  tier_type = {
    web = "public"
    app = "private"
    db  = "private"
  }

  effective_environments = {
    for env, config in var.environments : env => {
      index = config.index
      tiers = var.enable_nat_instance ? config.tiers : toset([for t in config.tiers : t if t != "app"])
    }
  }

  subnets = merge([
    for env, config in local.effective_environments : {
      for pair in setproduct(config.tiers, var.availability_zones) :
      "${env}-${pair[0]}-${substr(pair[1], -2, 2)}" => {
        environment       = env
        tier              = pair[0]
        availability_zone = pair[1]
        az_short          = substr(pair[1], -2, 2)
        subnet_type       = local.tier_type[pair[0]]
        cidr_block = cidrsubnet(
          cidrsubnet(var.vpc_cidr, 2, config.index),
          3,
          local.tier_index[pair[0]] * length(var.availability_zones) + index(var.availability_zones, pair[1])
        )
      }
    }
  ]...)

  web_subnets = { for k, v in local.subnets : k => v if v.tier == "web" }
  app_subnets = { for k, v in local.subnets : k => v if v.tier == "app" }
  db_subnets  = { for k, v in local.subnets : k => v if v.tier == "db" }

  primary_public_subnet_key = "com-web-${substr(var.availability_zones[0], -2, 2)}"

  private_route_table_ids = compact(concat(
    var.enable_nat_instance ? [aws_route_table.app[0].id] : [],
    [aws_route_table.db.id]
  ))
}
