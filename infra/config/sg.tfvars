aws_region         = "ap-southeast-1"
project_code       = "vpcsg"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]

enable_nat_instance  = false
enable_vpc_endpoints = true
enable_private_dns   = true
nat_instance_type    = "t4g.nano"
