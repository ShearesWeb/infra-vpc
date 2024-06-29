# https://visualsubnetcalc.com/index.html?c=1N4IgbiBcIIwgNCAtlEBBA6gZQSAzlKDAAwB0ZFA9DAGyGwXnnUDs9JTVMAHO41wE4+nZgCZiw-pVFxIoAPoA7VAAUATgBMABAFotAdwCmAI1zyAxqhABfRBzLcxshcujrteo6cQWr12wxMtGIScoFkwcTSziBKqpq6WgCGAA4pZpbQNnaMogAsTvRxbgl6qek+mSA2-jlMAMyizDBCYcXVlX4B9qQ0BVE8kr391K1EjH0hQ5NRMkWuIFgALgDmiV4ZfnVkLE2zMe3La54mm1m14aTcVOJD14VtC0eJ5WfV3YzcjvvzqM9laTeNQ+TAENGaY1iCyB-hBEVE31YQxgCOavDCPRRiJayNRs1C4yCeOiv2gAGEAJbrU6dc7bUgwergn6PVCU6neWJVGr0mB5Ea3DGMPkCg4LdkAipcraXGAAVj2JNZ5KpkphF0xNEEpI60vOcIZAkVgyFQSNEOR5vxlsVc2ViwAFh4DDS9e96eIbmK-k6OeqPcREYLCWRxEHvdAsL69BpOb46ZcZMylS4fc7Y+qDaJ8hb7YokpnYUA

locals {
  web_subnet_configuration = {
    prd-web-subnet-public-1a = {
      env               = "prd"
      cidr_block        = "10.0.0.0/21"
      availability_zone = "ap-southeast-1a"
      usable_hosts      = 2043
    }
    prd-web-subnet-public-1b = {
      env               = "prd"
      cidr_block        = "10.0.16.0/21"
      availability_zone = "ap-southeast-1b"
      usable_hosts      = 2043
    }
    preprd-web-subnet-public-1a = {
      env               = "preprd"
      cidr_block        = "10.0.64.0/21"
      availability_zone = "ap-southeast-1a"
      usable_hosts      = 2043
    }
    preprd-web-subnet-public-1b = {
      env               = "preprd"
      cidr_block        = "10.0.72.0/21"
      availability_zone = "ap-southeast-1b"
      usable_hosts      = 2043
    }
    stg-web-subnet-public-1a = {
      env               = "stg"
      cidr_block        = "10.0.128.0/21"
      availability_zone = "ap-southeast-1a"
      usable_hosts      = 2043
    }
    stg-web-subnet-public-1b = {
      env               = "stg"
      cidr_block        = "10.0.136.0/21"
      availability_zone = "ap-southeast-1b"
      usable_hosts      = 2043
    }
    com-web-subnet-public-1a = {
      env               = "com"
      cidr_block        = "10.0.192.0/21"
      availability_zone = "ap-southeast-1a"
      usable_hosts      = 2043
    }
    com-web-subnet-public-1b = {
      env               = "com"
      cidr_block        = "10.0.200.0/21"
      availability_zone = "ap-southeast-1b"
      usable_hosts      = 2043
    }
  }
  app_subnet_configuration = {
    prd-app-subnet-private-1a = {
      env               = "prd"
      cidr_block        = "10.0.16.0/21"
      availability_zone = "ap-southeast-1a"
      usable_hosts      = 2043
    }
    prd-app-subnet-private-1b = {
      env               = "prd"
      cidr_block        = "10.0.24.0/21"
      availability_zone = "ap-southeast-1b"
      usable_hosts      = 2043
    }
    preprd-app-subnet-private-1a = {
      env               = "preprd"
      cidr_block        = "10.0.80.0/21"
      availability_zone = "ap-southeast-1a"
      usable_hosts      = 2043
    }
    preprd-app-subnet-private-1b = {
      env               = "preprd"
      cidr_block        = "10.0.88.0/21"
      availability_zone = "ap-southeast-1b"
      usable_hosts      = 2043
    }
    stg-app-subnet-private-1a = {
      env               = "stg"
      cidr_block        = "10.0.144.0/21"
      availability_zone = "ap-southeast-1a"
      usable_hosts      = 2043
    }
    stg-app-subnet-private-1b = {
      env               = "stg"
      cidr_block        = "10.0.152.0/21"
      availability_zone = "ap-southeast-1b"
      usable_hosts      = 2043
    }
  }
  db_subnet_configuration = {
    com-db-subnet-private-1a = {
      env               = "com"
      cidr_block        = "10.0.208.0/21"
      availability_zone = "ap-southeast-1a"
      usable_hosts      = 2043
    }
    com-db-subnet-private-1b = {
      env               = "com"
      cidr_block        = "10.0.216.0/21"
      availability_zone = "ap-southeast-1b"
      usable_hosts      = 2043
    }
  }
}

resource "aws_subnet" "web" {
  for_each          = local.web_subnet_configuration
  vpc_id            = aws_vpc.common.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Environment = each.value.env
    Name        = each.key
    Zone        = "web"
    ProjectCode = var.project_code
    SubnetType  = "public"
    UsableHosts = each.value.usable_hosts
    VpcId       = aws_vpc.common.id
    VpcName     = local.vpc_name
  }
}

resource "aws_route_table_association" "web" {
  for_each       = local.web_subnet_configuration
  route_table_id = aws_route_table.web.id
  subnet_id      = aws_subnet.web[each.key].id
}

resource "aws_subnet" "app" {
  for_each          = local.app_subnet_configuration
  vpc_id            = aws_vpc.common.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Environment = each.value.env
    Name        = each.key
    Zone        = "app"
    ProjectCode = var.project_code
    SubnetType  = "private"
    UsableHosts = each.value.usable_hosts
    VpcId       = aws_vpc.common.id
    VpcName     = local.vpc_name
  }
}

resource "aws_route_table_association" "app" {
  for_each       = local.app_subnet_configuration
  route_table_id = aws_route_table.app.id
  subnet_id      = aws_subnet.app[each.key].id
}

resource "aws_subnet" "db" {
  for_each          = local.db_subnet_configuration
  vpc_id            = aws_vpc.common.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Environment = each.value.env
    Name        = each.key
    Zone        = "db"
    ProjectCode = var.project_code
    SubnetType  = "private"
    UsableHosts = each.value.usable_hosts
    VpcId       = aws_vpc.common.id
    VpcName     = local.vpc_name
  }
}

resource "aws_route_table_association" "db" {
  for_each       = local.db_subnet_configuration
  route_table_id = aws_route_table.db.id
  subnet_id      = aws_subnet.db[each.key].id
}
