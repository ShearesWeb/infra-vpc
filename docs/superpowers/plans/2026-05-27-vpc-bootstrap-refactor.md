# VPC Bootstrap Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure the Terraform VPC project to follow HashiCorp conventions, replace the deprecated NAT AMI with fck-nat, and make it portable for quick-bootstrapping a VPC in any AWS account.

**Architecture:** Flat root module with all resources driven by variables. Subnet CIDRs auto-derived via nested `cidrsubnet()`. NAT instance, VPC endpoints, and private DNS are optional. Backend config externalized to `.tfbackend` files.

**Tech Stack:** Terraform >= 1.6, AWS Provider ~> 6.0, fck-nat AMI (AL2023, arm64)

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `terraform.tf` | Create | Terraform block, required providers, S3 backend (empty) |
| `providers.tf` | Create | AWS provider config + default_tags |
| `variables.tf` | Rewrite | All input variables with types, descriptions, defaults, validation |
| `locals.tf` | Create | Subnet flattening, tier mappings, computed values |
| `data.tf` | Create | fck-nat AMI data source |
| `vpc.tf` | Rewrite | VPC + Internet Gateway |
| `subnets.tf` | Rewrite | All subnets via for_each on flattened locals |
| `routes.tf` | Create | Route tables, associations, main RT association |
| `nat.tf` | Create | fck-nat instance + security group |
| `dns.tf` | Rewrite | Optional private Route53 zone |
| `endpoints.tf` | Create | Optional S3/DynamoDB endpoints + EC2 Instance Connect |
| `outputs.tf` | Rewrite | Grouped outputs |
| `backends/sg.tfbackend` | Create | Example backend config |
| `main.tf` | Delete | Replaced by terraform.tf + providers.tf |
| `rtb.tf` | Delete | Replaced by routes.tf |
| `natinstance.tf` | Delete | Replaced by nat.tf |
| `vpce.tf` | Delete | Replaced by endpoints.tf |
| `ssm.tf` | Delete | SSM parameters removed |
| `modules/` | Delete | NAT module flattened into nat.tf |

---

### Task 1: Delete old files and module directory

**Files:**
- Delete: `modules/natinstance/instance.tf`
- Delete: `modules/natinstance/ami.tf`
- Delete: `modules/natinstance/sg.tf`
- Delete: `modules/natinstance/variables.tf`
- Delete: `modules/natinstance/output.tf`
- Delete: `modules/` directory
- Delete: `ssm.tf`
- Delete: `main.tf`
- Delete: `natinstance.tf`
- Delete: `rtb.tf`
- Delete: `vpce.tf`

- [ ] **Step 1: Remove modules directory and deleted root files**

```bash
rm -rf modules/
rm -f ssm.tf main.tf natinstance.tf rtb.tf vpce.tf
```

- [ ] **Step 2: Verify only files to rewrite remain**

```bash
ls *.tf
```

Expected output: `dns.tf outputs.tf subnets.tf variables.tf vpc.tf`

- [ ] **Step 3: Commit cleanup**

```bash
git add -A
git commit -m "chore: remove old module and files before restructure"
```

---

### Task 2: Create terraform.tf, providers.tf, and backends/

**Files:**
- Create: `terraform.tf`
- Create: `providers.tf`
- Create: `backends/sg.tfbackend`

- [ ] **Step 1: Create terraform.tf**

```hcl
# terraform.tf
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {}
}
```

- [ ] **Step 2: Create providers.tf**

```hcl
# providers.tf
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = var.project_code
    }
  }
}
```

- [ ] **Step 3: Create backends/sg.tfbackend**

```bash
mkdir -p backends
```

```ini
# backends/sg.tfbackend
bucket               = "com-all-bucket-terraform-state-algebananazzzzz"
key                  = "vpc.tfstate"
workspace_key_prefix = "tf-state"
region               = "ap-southeast-1"
```

- [ ] **Step 4: Commit**

```bash
git add terraform.tf providers.tf backends/
git commit -m "feat: add terraform.tf, providers.tf, and backend config"
```

---

### Task 3: Rewrite variables.tf

**Files:**
- Rewrite: `variables.tf`

- [ ] **Step 1: Replace variables.tf with all input variables (alphabetical order)**

```hcl
# variables.tf
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
```

- [ ] **Step 2: Commit**

```bash
git add variables.tf
git commit -m "feat: rewrite variables.tf with types, descriptions, and validation"
```

---

### Task 4: Create locals.tf and data.tf

**Files:**
- Create: `locals.tf`
- Create: `data.tf`

- [ ] **Step 1: Create locals.tf with subnet flattening logic**

```hcl
# locals.tf
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
```

- [ ] **Step 2: Create data.tf with fck-nat AMI lookup**

fck-nat auto-configures NAT on boot — no user data needed for single-instance mode. The AMI comes with iptables masquerade rules and IP forwarding pre-configured.

```hcl
# data.tf
data "aws_ami" "fck_nat" {
  count = var.enable_nat_instance ? 1 : 0

  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-al2023-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add locals.tf data.tf
git commit -m "feat: add locals.tf with subnet flattening and data.tf with fck-nat AMI"
```

---

### Task 5: Rewrite vpc.tf and subnets.tf

**Files:**
- Rewrite: `vpc.tf`
- Rewrite: `subnets.tf`

- [ ] **Step 1: Rewrite vpc.tf**

```hcl
# vpc.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_code}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_code}-igw"
  }
}
```

- [ ] **Step 2: Rewrite subnets.tf**

```hcl
# subnets.tf
resource "aws_subnet" "main" {
  for_each = local.subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name             = "${var.project_code}-${each.key}"
    Environment      = each.value.environment
    Tier             = each.value.tier
    SubnetType       = each.value.subnet_type
    AvailabilityZone = each.value.az_short
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add vpc.tf subnets.tf
git commit -m "feat: rewrite vpc.tf and subnets.tf with cidrsubnet and standardized tags"
```

---

### Task 6: Create routes.tf and nat.tf

**Files:**
- Create: `routes.tf`
- Create: `nat.tf`

- [ ] **Step 1: Create nat.tf with fck-nat instance and security group**

```hcl
# nat.tf
resource "aws_security_group" "nat" {
  count = var.enable_nat_instance ? 1 : 0

  name        = "${var.project_code}-nat-sg"
  description = "Allow all traffic from VPC to NAT instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_code}-nat-sg"
  }
}

resource "aws_instance" "nat" {
  count = var.enable_nat_instance ? 1 : 0

  ami                         = data.aws_ami.fck_nat[0].id
  instance_type               = var.nat_instance_type
  subnet_id                   = aws_subnet.main[local.primary_public_subnet_key].id
  vpc_security_group_ids      = [aws_security_group.nat[0].id]
  associate_public_ip_address = true
  source_dest_check           = false

  tags = {
    Name = "${var.project_code}-nat"
  }
}
```

- [ ] **Step 2: Create routes.tf with all route tables and associations**

```hcl
# routes.tf
resource "aws_route_table" "web" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_code}-web-rtb"
  }
}

resource "aws_route_table" "app" {
  count = var.enable_nat_instance ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat[0].primary_network_interface_id
  }

  tags = {
    Name = "${var.project_code}-app-rtb"
  }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_code}-db-rtb"
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "web" {
  for_each = local.web_subnets

  route_table_id = aws_route_table.web.id
  subnet_id      = aws_subnet.main[each.key].id
}

resource "aws_route_table_association" "app" {
  for_each = local.app_subnets

  route_table_id = aws_route_table.app[0].id
  subnet_id      = aws_subnet.main[each.key].id
}

resource "aws_route_table_association" "db" {
  for_each = local.db_subnets

  route_table_id = aws_route_table.db.id
  subnet_id      = aws_subnet.main[each.key].id
}
```

- [ ] **Step 3: Commit**

```bash
git add nat.tf routes.tf
git commit -m "feat: add fck-nat instance and route tables with conditional NAT toggle"
```

---

### Task 7: Rewrite dns.tf, create endpoints.tf, rewrite outputs.tf

**Files:**
- Rewrite: `dns.tf`
- Create: `endpoints.tf`
- Rewrite: `outputs.tf`

- [ ] **Step 1: Rewrite dns.tf with count toggle**

```hcl
# dns.tf
resource "aws_route53_zone" "private" {
  count = var.enable_private_dns ? 1 : 0

  name = "internal.${var.project_code}"

  vpc {
    vpc_id     = aws_vpc.main.id
    vpc_region = var.aws_region
  }

  tags = {
    Name = "internal.${var.project_code}"
  }
}
```

- [ ] **Step 2: Create endpoints.tf with free VPC endpoints and Instance Connect**

```hcl
# endpoints.tf
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = local.private_route_table_ids

  tags = {
    Name = "${var.project_code}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = local.private_route_table_ids

  tags = {
    Name = "${var.project_code}-dynamodb-endpoint"
  }
}

resource "aws_ec2_instance_connect_endpoint" "main" {
  count = var.enable_vpc_endpoints ? 1 : 0

  subnet_id          = aws_subnet.main[local.primary_public_subnet_key].id
  security_group_ids = var.enable_nat_instance ? [aws_security_group.nat[0].id] : []

  tags = {
    Name = "${var.project_code}-eice"
  }
}
```

- [ ] **Step 3: Rewrite outputs.tf (alphabetical)**

```hcl
# outputs.tf
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
```

- [ ] **Step 4: Commit**

```bash
git add dns.tf endpoints.tf outputs.tf
git commit -m "feat: add optional dns, vpc endpoints, instance connect, and outputs"
```

---

### Task 8: Format, validate, and final commit

- [ ] **Step 1: Run terraform fmt**

```bash
terraform fmt -recursive
```

Expected: list of files formatted (or no output if already formatted).

- [ ] **Step 2: Run terraform validate**

```bash
terraform init -backend=false
terraform validate
```

Expected: `Success! The configuration is valid.`

Note: `-backend=false` skips backend initialization so validate works without AWS credentials or S3 bucket access.

- [ ] **Step 3: Fix any validation errors**

If validate reports errors, fix them and re-run until it passes.

- [ ] **Step 4: Commit any formatting fixes**

```bash
git add -A
git commit -m "chore: terraform fmt and validate"
```

- [ ] **Step 5: Verify final file structure**

```bash
find . -name '*.tf' -o -name '*.tfbackend' | sort
```

Expected:
```
./backends/sg.tfbackend
./data.tf
./dns.tf
./endpoints.tf
./locals.tf
./nat.tf
./outputs.tf
./providers.tf
./routes.tf
./subnets.tf
./terraform.tf
./variables.tf
./vpc.tf
```
