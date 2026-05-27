variable "availability_zones" {
  description = "List of availability zones to deploy subnets across (max 2)"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]

  validation {
    condition     = length(var.availability_zones) >= 1 && length(var.availability_zones) <= 2
    error_message = "Between 1 and 2 availability zones are supported."
  }
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


variable "nat_instance_type" {
  description = "EC2 instance type for the fck-nat instance (must be arm64/Graviton)"
  type        = string
  default     = "t4g.nano"

  validation {
    condition     = can(regex("^(t4g|m6g|m7g|c6g|c7g|r6g|r7g)\\.", var.nat_instance_type))
    error_message = "nat_instance_type must be an arm64 Graviton instance type (e.g. t4g.nano)."
  }
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
