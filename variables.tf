variable "availability_zones" {
  description = "List of availability zones to deploy subnets across"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "enable_nat_instance" {
  description = "Deploy a fck-nat instance for private subnet internet access. When false, app-tier subnets are not created."
  type        = bool
  default     = true
}

variable "enable_private_dns" {
  description = "Create a private Route53 hosted zone for internal DNS"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Create free VPC endpoints (S3, DynamoDB gateways) and EC2 Instance Connect"
  type        = bool
  default     = true
}

variable "environments" {
  description = "Map of environments. Each gets a /18 CIDR block. Index controls allocation order (0-3)."
  type = map(object({
    index = number
    tiers = set(string)
  }))
  default = {
    prd = {
      index = 0
      tiers = ["web", "app"]
    }
    preprod = {
      index = 1
      tiers = ["web", "app"]
    }
    com = {
      index = 2
      tiers = ["web", "db"]
    }
  }

  validation {
    condition     = alltrue([for env in var.environments : env.index >= 0 && env.index <= 3])
    error_message = "Environment index must be between 0 and 3."
  }

  validation {
    condition     = alltrue([for env in var.environments : alltrue([for t in env.tiers : contains(["web", "app", "db"], t)])])
    error_message = "Tier must be one of: web, app, db."
  }
}

variable "nat_instance_type" {
  description = "EC2 instance type for the fck-nat instance"
  type        = string
  default     = "t4g.nano"
}

variable "project_code" {
  description = "Short project code used as naming prefix for all resources"
  type        = string
  default     = "vpcsg"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. All subnet CIDRs are automatically derived."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}
